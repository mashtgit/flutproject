import dotenv from 'dotenv';
dotenv.config({ path: '.env.production' });
process.env.NODE_ENV = 'production';
console.log('✅ Environment variables loaded');