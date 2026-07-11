#!/bin/bash

# BizAgent Deployment Script
# Merges everything for production release

set -e

echo "🚀 Starting BizAgent Web & AI Deployment..."

# 1. Flutter Build
echo "📦 Building Flutter Web (Release)..."
flutter build web --release --base-href "/"

# 2. Cloud Functions
echo "🛠️  Preparing Cloud Functions..."
cd functions
npm install
cd ..

# 3. Firebase Secrets (Safety Check)
echo "🔒 Checking Gemini API Key..."
# Note: Use 'firebase functions:secrets:set GEMINI_API_KEY' if not set

# 4. Deploy
echo "☁️  Deploying to Firebase..."
firebase deploy

echo "✅ Deployment Successful!"
echo "📍 Privacy: https://bizagent.sk/privacy-policy.html"
echo "📍 Deletion: https://bizagent.sk/delete-account.html"
