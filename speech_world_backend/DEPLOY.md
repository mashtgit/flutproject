# Cloud Run Deployment Guide

## Architecture

```
Flutter App (Mobile/Web)
        ↓ HTTPS
Google Cloud Run (Express Backend)
        ↓
Firebase / Google Cloud APIs
```

## Prerequisites

1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
2. Authenticate:
   ```bash
   gcloud auth login
   gcloud config set project speech-world-003
   ```
3. Enable Cloud Run API:
   ```bash
   gcloud services enable run.googleapis.com
   ```

## Deployment Steps

### 1. Set Environment Variables

Create `.env.production` file:

```env
NODE_ENV=production
PORT=3000
FIREBASE_PROJECT_ID=speech-world-003
FIREBASE_CLIENT_EMAIL=your-service-account@speech-world-003.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
```

### 2. Deploy to Cloud Run

**Option A: Using gcloud CLI**

```bash
# Navigate to backend directory
cd speech_world_backend

# Deploy
gcloud run deploy speech-world-backend \
  --source . \
  --region europe-west3 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "NODE_ENV=production" \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10
```

**Option B: Using deployment script**

```bash
chmod +x deploy-cloud-run.sh
./deploy-cloud-run.sh
```

### 3. Get Backend URL

After deployment, you'll get a URL like:
```
https://speech-world-backend-xxxxx.run.app
```

### 4. Update Flutter Configuration

Update `speech_world/lib/src/core/config/api_config.dart`:

```dart
static const String prodBaseUrl = 'https://speech-world-backend-xxxxx.run.app';
```

Replace `xxxxx` with your actual service ID.

## Local Development

```bash
npm run dev
# Server runs on http://localhost:3000
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_ENV` | `development` or `production` | Yes |
| `PORT` | Server port (default: 3000) | No |
| `FIREBASE_PROJECT_ID` | Firebase project ID | Yes |
| `FIREBASE_CLIENT_EMAIL` | Service account email | Yes |
| `FIREBASE_PRIVATE_KEY` | Service account private key | Yes |
| `JWT_SECRET` | Secret for JWT tokens | Yes |

## Monitoring

View logs:
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=speech-world-backend" --limit=50
```

## Updating Deployment

Simply run the deploy command again - Cloud Run will create a new revision.