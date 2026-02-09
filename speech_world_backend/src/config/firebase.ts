import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from '../utils/logger.js';

/**
 * Инициализация Firebase Admin SDK
 */
export function connectFirebase() {
  try {
    const isDevelopment = process.env.NODE_ENV !== 'production';

    // 1. Безопасная проверка: проинициализировано ли приложение?
    if (admin.apps?.length > 0) {
      return admin.app();
    }

    // 2. Получение и очистка переменных окружения
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    
    let privateKey = process.env.FIREBASE_PRIVATE_KEY;
    if (privateKey) {
      privateKey = privateKey.replace(/^"|"$/g, '').replace(/\\n/g, '\n');
    }

    if (!projectId || !privateKey || !clientEmail) {
      if (isDevelopment) {
        logger.warn('Firebase environment variables are missing. Firebase features will be unavailable.');
        return null;
      }
      throw new Error(`Missing Firebase config: ProjectID: ${!!projectId}, Key: ${!!privateKey}, Email: ${!!clientEmail}`);
    }

    // 3. Сборка объекта учетных данных
    const serviceAccount: admin.ServiceAccount = {
      projectId,
      clientEmail,
      privateKey,
      ...(process.env.FIREBASE_PRIVATE_KEY_ID && { privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID }),
      ...(process.env.FIREBASE_CLIENT_ID && { clientId: process.env.FIREBASE_CLIENT_ID }),
    };

    // 4. Инициализация
    const firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId
    });

    logger.info(`Firebase Admin SDK initialized successfully in ${isDevelopment ? 'development' : 'production'} mode`);
    return firebaseApp;

  } catch (error: any) {
    console.error('--- FIREBASE INIT ERROR DETAILS ---');
    console.error(error);
    console.error('-----------------------------------');

    logger.error('Failed to initialize Firebase Admin SDK:', {
      message: error.message,
      stack: error.stack
    });

    if (process.env.NODE_ENV === 'production') {
      throw new Error(`Firebase initialization failed: ${error.message}`);
    }
    return null;
  }
}

// Геттеры сервисов
export const db = (): admin.firestore.Firestore => {
  connectFirebase();
  // Database ID is 'default' (not '(default)')
  return getFirestore(admin.app(), 'default');
};

export const auth = (): admin.auth.Auth => {
  connectFirebase();
  return admin.auth();
};

export const storage = (): admin.storage.Storage => {
  connectFirebase();
  return admin.storage();
};

export const messaging = (): admin.messaging.Messaging => {
  connectFirebase();
  return admin.messaging();
};

/**
 * Экспорт инициализированного приложения и конфига
 */
export const firebaseApp = connectFirebase();

export const config = {
  port: parseInt(process.env.PORT || '3000'),
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID,
  nodeEnv: process.env.NODE_ENV || 'development'
};

export default firebaseApp;
