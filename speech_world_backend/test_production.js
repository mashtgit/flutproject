import dotenv from 'dotenv';
import path from 'path';

// 1. ПЕРВООЧЕРЕДНАЯ ЗАГРУЗКА КОНФИГА
// Загружаем переменные окружения строго до импорта других модулей
const envResult = dotenv.config({ path: '.env.production' });
process.env.NODE_ENV = 'production';

if (envResult.error) {
  console.error('❌ Could not find .env.production file!');
  process.exit(1);
}

console.log('✅ Environment variables loaded from .env.production');

// 2. ДИНАМИЧЕСКИЙ ИМПОРТ МОДУЛЕЙ
// Используем await import внутри async функции, чтобы Firebase не инициализировался раньше времени
async function runTests() {
  try {
    console.log('🚀 Starting Firebase Production Tests...\n');

    // Импортируем модули из dist
    const { connectFirebase } = await import('./dist/config/firebase.js');
    const AuthModule = await import('./dist/services/auth.service.js');
    const UserModule = await import('./dist/services/user.service.js');

    const AuthService = AuthModule.AuthService;
    const UserService = UserModule.UserService;

    // Вывод отладочной информации (без секретов)
    console.log('--- Step 1: Initialization ---');
    console.log('Checking Credentials:', {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      hasKey: !!process.env.FIREBASE_PRIVATE_KEY,
    });

    const app = connectFirebase();
    if (!app) throw new Error('Firebase app failed to initialize (returned null)');
    console.log('✅ Firebase Admin SDK Ready\n');

    // 2. Auth Test
    console.log('--- Step 2: Auth Service ---');
    const testEmail = `test-${Date.now()}@example.com`;
    const user = await AuthService.createUser(testEmail, 'password123', { 
      displayName: 'Prod Test' 
    });
    console.log(`✅ User created: ${user.uid}`);
    
    await AuthService.deleteUser(user.uid);
    console.log('✅ User cleaned up\n');

    // 3. Firestore Test
    console.log('--- Step 3: User Service (Firestore) ---');
    const tempId = 'test-id-' + Date.now();
    await UserService.createUserProfile(tempId, { 
      email: testEmail, 
      displayName: 'Firestore Test' 
    });
    console.log('✅ Firestore write successful');
    
    await UserService.deleteUserProfile(tempId);
    console.log('✅ Firestore cleanup successful\n');

    console.log('🎉 ALL TESTS PASSED SUCCESSFULLY!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ TEST FAILED:');
    // Выводим ошибку целиком для диагностики
    if (error.message) console.error('Message:', error.message);
    if (error.stack) console.error('Stack:', error.stack);
    process.exit(1);
  }
}

runTests();