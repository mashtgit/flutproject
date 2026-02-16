/**
 * Vertex AI Service - REAL IMPLEMENTATION
 * 
 * Manages Gemini Live API sessions for Dialogue Mode.
 * Handles WebSocket connections to Vertex AI and audio streaming.
 * 
 * @module services/vertexai
 */

import WebSocket from 'ws';
import { logger } from '../utils/logger.js';
import { GoogleAuth } from 'google-auth-library';

// Configuration constants
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'speech-world-003';
const LOCATION = 'europe-west1';
const MODEL = 'gemini-live-2.5-flash-native-audio';

// Vertex AI WebSocket endpoint
function getVertexWebSocketUrl(accessToken: string): string {
  return `wss://${LOCATION}-aiplatform.googleapis.com/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent`;
}

/**
 * Supported languages for Dialogue Mode
 */
export const SUPPORTED_LANGUAGES = [
  { code: 'en', name: 'English', voice: 'en-US' },
  { code: 'ru', name: 'Russian', voice: 'ru-RU' },
  { code: 'ka', name: 'Georgian', voice: 'ka-GE' },
  { code: 'es', name: 'Spanish', voice: 'es-ES' },
  { code: 'fr', name: 'French', voice: 'fr-FR' },
  { code: 'de', name: 'German', voice: 'de-DE' },
  { code: 'it', name: 'Italian', voice: 'it-IT' },
  { code: 'pt', name: 'Portuguese', voice: 'pt-PT' },
  { code: 'zh', name: 'Chinese', voice: 'zh-CN' },
  { code: 'ja', name: 'Japanese', voice: 'ja-JP' },
  { code: 'ko', name: 'Korean', voice: 'ko-KR' },
  { code: 'ar', name: 'Arabic', voice: 'ar-SA' },
];

/**
 * Session state interface
 */
interface SessionState {
  sessionId: string;
  userId: string;
  l1Language: string;
  l2Language: string;
  vertexSocket?: WebSocket;
  clientSocket?: WebSocket;
  isActive: boolean;
  createdAt: Date;
  lastActivity: Date;
  audioBuffer: Buffer[];
  accessToken?: string;
}

/**
 * Active sessions map
 */
const sessions = new Map<string, SessionState>();

/**
 * Google Auth client
 */
let authClient: GoogleAuth | null = null;

/**
 * Initialize Google Auth
 */
function getAuthClient(): GoogleAuth {
  if (!authClient) {
    authClient = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
  }
  return authClient;
}

/**
 * Generate system prompt for Dialogue Mode
 */
function generateDialoguePrompt(l1: string, l2: string): string {
  const l1Name = SUPPORTED_LANGUAGES.find(l => l.code === l1)?.name || l1;
  const l2Name = SUPPORTED_LANGUAGES.find(l => l.code === l2)?.name || l2;

  return `You are a professional real-time interpreter for conversations between people speaking ${l1Name} and ${l2Name}.

YOUR TASK:
- Listen to audio and identify the language (${l1Name} or ${l2Name})
- Translate speech to the other language in real-time
- Speak the translation in a natural, conversational voice

RULES:
1. If you hear ${l1Name} (L1) → translate to ${l2Name} (L2)
2. If you hear ${l2Name} (L2) → translate to ${l1Name} (L1)
3. DO NOT add any explanations or commentary
4. DO NOT repeat what was said, only the translation
5. Use natural, conversational style
6. Maintain the emotional tone of the speaker

LANGUAGES:
- L1: ${l1Name} (${l1})
- L2: ${l2Name} (${l2})

Respond ONLY with the translation, no language labels or comments.`;
}

/**
 * Create Gemini Live setup message
 */
function createSetupMessage(l1: string, l2: string): object {
  const systemPrompt = generateDialoguePrompt(l1, l2);
  
  return {
    setup: {
      model: `projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL}`,
      generation_config: {
        response_modalities: ['AUDIO'],
        speech_config: {
          voice_config: {
            prebuilt_voice_config: {
              voice_name: 'Puck', // Natural conversational voice
            },
          },
        },
      },
      system_instruction: {
        parts: [
          {
            text: systemPrompt,
          },
        ],
      },
    },
  };
}

/**
 * Create Gemini Live session
 */
export async function createLiveSession(
  sessionId: string,
  userId: string,
  l1Language: string,
  l2Language: string
): Promise<SessionState> {
  try {
    logger.info(`Creating Vertex AI session: ${sessionId} for user: ${userId}`);

    // Create session state
    const session: SessionState = {
      sessionId,
      userId,
      l1Language,
      l2Language,
      isActive: true,
      createdAt: new Date(),
      lastActivity: new Date(),
      audioBuffer: [],
    };

    sessions.set(sessionId, session);

    logger.info(`Vertex AI session created: ${sessionId}`);
    return session;
  } catch (error) {
    logger.error('Failed to create Vertex AI session:', error);
    throw new Error('Failed to initialize Gemini Live session');
  }
}

/**
 * Get access token for Vertex AI
 */
async function getAccessToken(): Promise<string> {
  try {
    const auth = getAuthClient();
    const client = await auth.getClient();
    const token = await client.getAccessToken();
    
    if (!token.token) {
      throw new Error('Failed to obtain access token');
    }
    
    logger.info('Successfully obtained access token for Vertex AI');
    return token.token;
  } catch (error) {
    logger.error('Failed to get access token:', error);
    throw new Error('Authentication failed for Vertex AI');
  }
}

/**
 * Connect to Gemini Live WebSocket
 * 
 * REAL IMPLEMENTATION: Connects to actual Vertex AI Gemini Live API
 */
export async function connectVertexWebSocket(
  sessionId: string,
  l1Language: string,
  l2Language: string
): Promise<WebSocket> {
  return new Promise(async (resolve, reject) => {
    try {
      const session = sessions.get(sessionId);
      if (!session) {
        throw new Error(`Session not found: ${sessionId}`);
      }

      logger.info(`Connecting to Vertex AI Live API for session: ${sessionId}`);
      logger.info(`Languages: ${l1Language} ↔ ${l2Language}`);

      // Get access token
      const accessToken = await getAccessToken();
      session.accessToken = accessToken;

      // Create WebSocket connection to Vertex AI
      const wsUrl = getVertexWebSocketUrl(accessToken);
      const vertexSocket = new WebSocket(wsUrl, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      });

      // Handle connection open
      vertexSocket.on('open', () => {
        logger.info(`✅ Vertex AI WebSocket connected for session: ${sessionId}`);
        
        // Send setup message
        const setupMessage = createSetupMessage(l1Language, l2Language);
        vertexSocket.send(JSON.stringify(setupMessage));
        logger.info(`Setup message sent for session: ${sessionId}`);
        
        resolve(vertexSocket);
      });

      // Handle errors
      vertexSocket.on('error', (error) => {
        logger.error(`❌ Vertex AI WebSocket error for session ${sessionId}:`, error);
        reject(error);
      });

      // Handle close
      vertexSocket.on('close', (code, reason) => {
        logger.info(`Vertex AI WebSocket closed for session ${sessionId}: code=${code}, reason=${reason}`);
        
        // Notify client if still connected
        if (session.clientSocket?.readyState === WebSocket.OPEN) {
          session.clientSocket.send(JSON.stringify({
            type: 'error',
            sessionId,
            message: 'Vertex AI connection closed',
          }));
        }
      });

      session.vertexSocket = vertexSocket;
    } catch (error) {
      logger.error('Failed to connect Vertex WebSocket:', error);
      reject(error);
    }
  });
}

/**
 * Handle message from Vertex AI
 */
export function handleVertexMessage(
  sessionId: string,
  message: WebSocket.RawData,
  onAudioResponse: (audioData: Buffer) => void
): void {
  try {
    const session = sessions.get(sessionId);
    if (!session) {
      logger.warn(`Session not found for message: ${sessionId}`);
      return;
    }

    // Parse the message
    const data = JSON.parse(message.toString());
    
    // Handle server content
    if (data.serverContent) {
      // Handle model turn with audio
      if (data.serverContent.modelTurn) {
        const parts = data.serverContent.modelTurn.parts || [];
        
        for (const part of parts) {
          // Handle inline audio data
          if (part.inlineData) {
            const audioData = Buffer.from(part.inlineData.data, 'base64');
            logger.info(`🎵 Received audio from Vertex AI: ${audioData.length} bytes`);
            onAudioResponse(audioData);
          }
          
          // Handle text response (if any)
          if (part.text) {
            logger.info(`📝 Text from Vertex AI: ${part.text.substring(0, 100)}...`);
          }
        }
      }
      
      // Handle turn completion
      if (data.serverContent.turnComplete) {
        logger.info(`✅ Turn complete for session: ${sessionId}`);
      }
    }

    // Handle setup complete
    if (data.setupComplete) {
      logger.info(`✅ Setup complete for session: ${sessionId}`);
    }

    // Update last activity
    session.lastActivity = new Date();
  } catch (error) {
    logger.error(`Failed to handle Vertex message for session ${sessionId}:`, error);
  }
}

/**
 * Get session by ID
 */
export function getSession(sessionId: string): SessionState | undefined {
  return sessions.get(sessionId);
}

/**
 * Close session
 */
export function closeSession(sessionId: string): void {
  const session = sessions.get(sessionId);
  if (session) {
    // Close Vertex WebSocket
    if (session.vertexSocket && session.vertexSocket.readyState === WebSocket.OPEN) {
      // Send end of session message if needed
      session.vertexSocket.close();
      logger.info(`Vertex WebSocket closed for session: ${sessionId}`);
    }

    // Close client WebSocket
    if (session.clientSocket && session.clientSocket.readyState === WebSocket.OPEN) {
      session.clientSocket.close();
    }

    session.isActive = false;
    sessions.delete(sessionId);

    logger.info(`Session closed: ${sessionId}`);
  }
}

/**
 * Forward audio from client to Vertex AI
 * 
 * Converts PCM audio to Gemini Live API format and sends it.
 * If session is not active, buffers audio for later sending.
 */
export function forwardAudioToVertex(sessionId: string, audioData: Buffer): void {
  const session = sessions.get(sessionId);
  if (!session) {
    logger.warn(`Cannot forward audio: session ${sessionId} not found`);
    return;
  }

  // If Vertex AI socket is not open yet, buffer audio
  if (!session.vertexSocket || session.vertexSocket.readyState !== WebSocket.OPEN) {
    logger.debug(`Buffering audio: session ${sessionId} not ready (${audioData.length} bytes)`);
    session.audioBuffer.push(audioData);
    return;
  }

  try {
    // Send buffered audio first
    if (session.audioBuffer.length > 0) {
      logger.debug(`Sending buffered audio: ${session.audioBuffer.length} chunks`);
      for (const bufferedData of session.audioBuffer) {
        const bufferMessage = {
          clientContent: {
            turns: [
              {
                role: 'user',
                parts: [
                  {
                    inlineData: {
                      mimeType: 'audio/pcm;rate=16000',
                      data: bufferedData.toString('base64'),
                    },
                  },
                ],
              },
            ],
            turnComplete: false,
          },
        };
        session.vertexSocket.send(JSON.stringify(bufferMessage));
      }
      session.audioBuffer = [];
    }

    // Send current audio
    const message = {
      clientContent: {
        turns: [
          {
            role: 'user',
            parts: [
              {
                inlineData: {
                  mimeType: 'audio/pcm;rate=16000',
                  data: audioData.toString('base64'),
                },
              },
            ],
          },
        ],
        turnComplete: false, // Don't complete turn, keep listening
      },
    };

    session.vertexSocket.send(JSON.stringify(message));
    
    logger.debug(`Audio forwarded to Vertex AI for session ${sessionId} (${audioData.length} bytes)`);
    session.lastActivity = new Date();
  } catch (error) {
    logger.error(`Failed to forward audio for session ${sessionId}:`, error);
  }
}

/**
 * Complete the current turn (signal end of user speech)
 */
export function completeTurn(sessionId: string): void {
  const session = sessions.get(sessionId);
  if (!session) {
    logger.warn(`Cannot complete turn: session ${sessionId} not found`);
    return;
  }
  
  if (!session.vertexSocket) {
    logger.warn(`Cannot complete turn: no Vertex AI socket for session ${sessionId}`);
    return;
  }
  
  if (session.vertexSocket.readyState !== WebSocket.OPEN) {
    logger.warn(`Cannot complete turn: Vertex AI socket not open for session ${sessionId}, state: ${session.vertexSocket.readyState}`);
    return;
  }

  try {
    // Signal that the user has finished speaking
    const message = {
      clientContent: {
        turns: [],
        turnComplete: true,
      },
    };

    session.vertexSocket.send(JSON.stringify(message));
    logger.info(`✅ Turn complete signal sent to Vertex AI for session: ${sessionId}`);
  } catch (error) {
    logger.error(`Failed to complete turn for session ${sessionId}:`, error);
  }
}

/**
 * Get all active sessions
 */
export function getActiveSessions(): SessionState[] {
  return Array.from(sessions.values()).filter(s => s.isActive);
}

/**
 * Cleanup inactive sessions
 */
export function cleanupInactiveSessions(maxInactiveMinutes: number = 30): void {
  const now = new Date();
  const sessionsToClose: string[] = [];

  for (const [sessionId, session] of sessions) {
    const inactiveTime = (now.getTime() - session.lastActivity.getTime()) / 1000 / 60;
    if (inactiveTime > maxInactiveMinutes) {
      sessionsToClose.push(sessionId);
    }
  }

  for (const sessionId of sessionsToClose) {
    logger.info(`Closing inactive session: ${sessionId}`);
    closeSession(sessionId);
  }
}

export default {
  createLiveSession,
  connectVertexWebSocket,
  getSession,
  closeSession,
  forwardAudioToVertex,
  completeTurn,
  handleVertexMessage,
  getActiveSessions,
  cleanupInactiveSessions,
  SUPPORTED_LANGUAGES,
};
