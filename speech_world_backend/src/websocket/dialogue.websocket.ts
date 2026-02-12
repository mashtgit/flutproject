/**
 * Dialogue WebSocket Handler
 * 
 * Manages WebSocket connections from Flutter clients for Dialogue Mode.
 * Proxies audio/text between client and Vertex AI Gemini Live API.
 * 
 * @module websocket/dialogue
 */

import WebSocket from 'ws';
import { IncomingMessage } from 'http';
import { logger } from '../utils/logger.js';
import {
  createLiveSession,
  connectVertexWebSocket,
  closeSession,
  forwardAudioToVertex,
  handleVertexMessage,
  getSession,
  cleanupInactiveSessions,
  SUPPORTED_LANGUAGES,
} from '../services/vertexai.service.js';

// Session cleanup interval (every 5 minutes)
const CLEANUP_INTERVAL = 5 * 60 * 1000;

/**
 * Client message types
 */
interface ClientMessage {
  type: 'start' | 'audio' | 'text' | 'stop';
  sessionId?: string;
  l1Language?: string;
  l2Language?: string;
  data?: string; // base64 encoded audio or text
}

/**
 * Server message types
 */
interface ServerMessage {
  type: 'connected' | 'started' | 'audio' | 'text' | 'error' | 'stopped';
  sessionId?: string;
  data?: string; // base64 encoded audio or text
  message?: string;
  supportedLanguages?: typeof SUPPORTED_LANGUAGES;
}

/**
 * Initialize periodic cleanup of inactive sessions
 */
export function initSessionCleanup(): void {
  setInterval(() => {
    cleanupInactiveSessions(30);
  }, CLEANUP_INTERVAL);

  logger.info('Session cleanup initialized (every 5 minutes)');
}

/**
 * Handle new WebSocket connection
 */
export function handleDialogueConnection(ws: WebSocket, req: IncomingMessage): void {
  const clientId = generateClientId();
  logger.info(`New dialogue connection: ${clientId} from ${req.socket.remoteAddress}`);

  // Send supported languages on connection
  const connectMessage: ServerMessage = {
    type: 'connected',
    supportedLanguages: SUPPORTED_LANGUAGES,
  };
  ws.send(JSON.stringify(connectMessage));

  // Handle messages from client
  ws.on('message', async (data: WebSocket.RawData) => {
    try {
      await handleClientMessage(ws, data, clientId);
    } catch (error) {
      logger.error(`Error handling message from ${clientId}:`, error);
      sendError(ws, 'Failed to process message');
    }
  });

  // Handle connection close
  ws.on('close', (code: number, reason: Buffer) => {
    logger.info(`Connection closed: ${clientId}, code: ${code}, reason: ${reason.toString()}`);
    cleanupClientSessions(clientId);
  });

  // Handle errors
  ws.on('error', (error: Error) => {
    logger.error(`WebSocket error for ${clientId}:`, error);
  });

  // Set ping/pong to keep connection alive
  setupHeartbeat(ws, clientId);
}

/**
 * Handle message from client
 */
async function handleClientMessage(
  ws: WebSocket,
  data: WebSocket.RawData,
  clientId: string
): Promise<void> {
  try {
    const message: ClientMessage = JSON.parse(data.toString());
    logger.debug(`Received ${message.type} from ${clientId}`);

    switch (message.type) {
      case 'start':
        await handleStartSession(ws, message, clientId);
        break;

      case 'audio':
        handleAudioData(message);
        break;

      case 'text':
        handleTextData(message);
        break;

      case 'stop':
        handleStopSession(message);
        break;

      default:
        logger.warn(`Unknown message type from ${clientId}: ${message.type}`);
        sendError(ws, `Unknown message type: ${message.type}`);
    }
  } catch (error) {
    logger.error(`Failed to parse message from ${clientId}:`, error);
    sendError(ws, 'Invalid message format');
  }
}

/**
 * Handle session start
 */
async function handleStartSession(
  ws: WebSocket,
  message: ClientMessage,
  clientId: string
): Promise<void> {
  try {
    const { sessionId, l1Language = 'en', l2Language = 'ru' } = message;

    if (!sessionId) {
      sendError(ws, 'sessionId is required');
      return;
    }

    // Validate languages
    if (!isValidLanguage(l1Language) || !isValidLanguage(l2Language)) {
      sendError(ws, 'Invalid language code');
      return;
    }

    logger.info(`Starting session ${sessionId} for ${clientId}: ${l1Language} ↔ ${l2Language}`);

    // Create session
    const session = await createLiveSession(sessionId, clientId, l1Language, l2Language);

    // Connect to Vertex AI
    const vertexSocket = await connectVertexWebSocket(sessionId, l1Language, l2Language);

    // Store client socket
    session.clientSocket = ws;

    // Set up message handler from Vertex AI
    vertexSocket.on('message', (data: WebSocket.RawData) => {
      handleVertexMessage(sessionId, data, (audioData: Buffer) => {
        // Send audio back to client
        const response: ServerMessage = {
          type: 'audio',
          sessionId,
          data: audioData.toString('base64'),
        };

        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(response));
        }
      });
    });

    // Send confirmation to client
    const response: ServerMessage = {
      type: 'started',
      sessionId,
      message: `Session started: ${l1Language} ↔ ${l2Language}`,
    };
    ws.send(JSON.stringify(response));

    logger.info(`Session ${sessionId} started successfully`);
  } catch (error) {
    logger.error(`Failed to start session:`, error);
    sendError(ws, 'Failed to start session');
  }
}

/**
 * Handle audio data from client
 */
function handleAudioData(message: ClientMessage): void {
  const { sessionId, data } = message;

  if (!sessionId || !data) {
    logger.warn('Missing sessionId or data in audio message');
    return;
  }

  const session = getSession(sessionId);
  if (!session) {
    logger.warn(`Session not found: ${sessionId}`);
    return;
  }

  try {
    const audioBuffer = Buffer.from(data, 'base64');
    forwardAudioToVertex(sessionId, audioBuffer);
  } catch (error) {
    logger.error(`Failed to process audio for session ${sessionId}:`, error);
  }
}

/**
 * Handle text data from client
 */
function handleTextData(message: ClientMessage): void {
  // Text messages can be used for transcription or commands
  // For now, we'll just log them
  const { sessionId, data } = message;
  logger.debug(`Text message from session ${sessionId}: ${data?.substring(0, 100)}...`);
}

/**
 * Handle session stop
 */
function handleStopSession(message: ClientMessage): void {
  const { sessionId } = message;

  if (!sessionId) {
    logger.warn('Missing sessionId in stop message');
    return;
  }

  logger.info(`Stopping session: ${sessionId}`);
  closeSession(sessionId);
}

/**
 * Send error message to client
 */
function sendError(ws: WebSocket, errorMessage: string): void {
  const response: ServerMessage = {
    type: 'error',
    message: errorMessage,
  };

  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(response));
  }
}

/**
 * Validate language code
 */
function isValidLanguage(code: string): boolean {
  return SUPPORTED_LANGUAGES.some(lang => lang.code === code);
}

/**
 * Generate unique client ID
 */
function generateClientId(): string {
  return `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Cleanup all sessions for a client
 */
function cleanupClientSessions(clientId: string): void {
  // In a real implementation, we would track which sessions belong to which client
  // For now, we'll rely on the session cleanup interval
  logger.info(`Cleaning up sessions for client: ${clientId}`);
}

/**
 * Setup heartbeat to keep connection alive
 */
function setupHeartbeat(ws: WebSocket, clientId: string): void {
  const pingInterval = 30000; // 30 seconds

  const interval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.ping();
    } else {
      clearInterval(interval);
    }
  }, pingInterval);

  ws.on('pong', () => {
    logger.debug(`Pong received from ${clientId}`);
  });

  ws.on('close', () => {
    clearInterval(interval);
  });
}

export default {
  handleDialogueConnection,
  initSessionCleanup,
};
