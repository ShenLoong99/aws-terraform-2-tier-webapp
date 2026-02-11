#!/bin/bash

# --- Best Practices: Strict Mode ---
# -e: Exit on error | -u: Exit on undefined variables | -o pipefail: Catch errors in pipes
set -euo pipefail

# Check if ALB_DNS is provided
if [ -z "${ALB_DNS:-}" ]; then
  echo "❌ Error: ALB_DNS environment variable is not set."
  exit 1
fi

BASE_URL="http://${ALB_DNS}:3000"

echo "--------------------------------------------------"
echo "🚀 Starting Deployment Verification for: $BASE_URL"
echo "--------------------------------------------------"

# --- Step 1: Health Check (Retries) ---
echo "🔎 Step 1: Checking application health..."
MAX_ATTEMPTS=10
SLEEP_TIME=30

for i in $(seq 1 $MAX_ATTEMPTS); do
  # Get HTTP status code
  STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$BASE_URL/health" || echo "failed")

  if [ "$STATUS" == "200" ]; then
    echo "✅ Application is Healthy! (Attempt $i)"
    break
  else
    if [ "$i" -eq "$MAX_ATTEMPTS" ]; then
      echo "❌ Health check timed out after $MAX_ATTEMPTS attempts."
      exit 1
    fi
    echo "⏳ Attempt $i/$MAX_ATTEMPTS: Status is '$STATUS'. Retrying in ${SLEEP_TIME}s..."
    sleep $SLEEP_TIME
  fi
done

# --- Step 2: Integration Test (Data Connectivity) ---
echo -e "\n🔎 Step 2: Testing Database Connectivity via API..."
# curl --fail will exit with non-zero if the response is 4xx or 5xx
if curl --fail -s "$BASE_URL/items" > /dev/null; then
  echo "✅ Database connectivity verified. API returned valid data."
else
  echo "❌ Integration Test Failed: Could not fetch items from database."
  exit 1
fi

echo -e "\n✨ All deployment verifications passed successfully!"
