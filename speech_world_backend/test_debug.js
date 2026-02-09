import dotenv from 'dotenv';
import path from 'path';

const envResult = dotenv.config({ path: '.env.production' });
process.env.NODE_ENV = 'production';

if (envResult.error) {
  console.error('❌ Could not find .env.production file!');
  process.exit(1);
}

console.log('✅ Environment variables loaded from .env.production');

async function runDebug() {
  try {
    const { connectFirebase, db } = await import('./dist/config/firebase.js');
    
    console.log('\n--- Debug Firestore Connection ---');
    const app = connectFirebase();
    if (!app) {
      console.error('❌ Firebase app failed to initialize');
      process.exit(1);
    }
    
    console.log('✅ Firebase app initialized');
    console.log('Project ID:', process.env.FIREBASE_PROJECT_ID);
    
    // Try to get Firestore instance
    const firestore = db();
    console.log('✅ Firestore instance created');
    
    // Try a simple operation - list collections
    console.log('\nTrying to list collections...');
    const collections = await firestore.listCollections();
    console.log('✅ Collections:', collections.map(c => c.id));
    
    // Try to write a test document
    console.log('\nTrying to write test document...');
    const testRef = firestore.collection('test').doc('debug');
    await testRef.set({ test: true, timestamp: new Date().toISOString() });
    console.log('✅ Test document written successfully');
    
    // Clean up
    await testRef.delete();
    console.log('✅ Test document cleaned up');
    
    console.log('\n🎉 DEBUG TEST PASSED!');
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ DEBUG TEST FAILED:');
    console.error('Error:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error details:', error.details);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

runDebug();
