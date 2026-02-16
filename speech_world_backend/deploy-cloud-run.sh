#!/bin/bash

# Cloud Run Deployment Script
# Usage: ./deploy-cloud-run.sh [service-name] [region]

SERVICE_NAME=${1:-"speech-world-backend"}
REGION=${2:-"europe-west1"}
PROJECT_ID="speech-world-003"

echo "🚀 Deploying to Cloud Run..."
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"
echo "Project: $PROJECT_ID"

# Set project
gcloud config set project $PROJECT_ID

# Build and deploy
gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "NODE_ENV=production" \
  --memory 512Mi \
  --cpu 1 \
  --concurrency 80 \
  --max-instances 10 \
  --min-instances 0

echo "✅ Deployment complete!"
echo ""
echo "Your backend URL:"
gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)'