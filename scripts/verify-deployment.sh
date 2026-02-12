#!/bin/bash

# --- Best Practices: Strict Mode ---
# -e: Exit on error | -u: Exit on undefined variables | -o pipefail: Catch errors in pipes
set -euo pipefail

# Check if APP_URL is provided
if [ -z "${APP_URL:-}" ]; then
  echo "❌ Error: APP_URL environment variable is not set."
  exit 1
fi

BASE_URL=${APP_URL}

echo "--------------------------------------------------"
echo "🚀 Starting Deployment Verification for: $BASE_URL"
echo "--------------------------------------------------"

# --- Step 1: Health Check (Retries) ---
echo "🔎 Step 1: Checking application health..."
MAX_ATTEMPTS=10
SLEEP_TIME=30

for i in $(seq 1 $MAX_ATTEMPTS); do
  # Added --connect-timeout to prevent hanging too long on a dead connection
  # Added -w to capture BOTH the http_code and the exit status
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$BASE_URL/health" || echo "000")
  EXIT_CODE=$?

  if [ "$RESPONSE" == "200" ]; then
    echo -e "\n✅ Application is Healthy! (Attempt $i)"
    break
  else
    # Provide visual feedback and specific error details
    echo -n "⏳ Attempt $i/$MAX_ATTEMPTS: Status '$RESPONSE' (Curl Exit: $EXIT_CODE). Retrying in ${SLEEP_TIME}s "

    # Progress interval: Print a dot every 5 seconds during the wait
    for ((j=0; j<SLEEP_TIME; j+=5)); do
      sleep 5
      echo -n "."
    done
    echo "" # New line for the next attempt

    if [ "$i" -eq "$MAX_ATTEMPTS" ]; then
      echo "❌ Health check timed out after $MAX_ATTEMPTS attempts."
      exit 1
    fi
  fi
done

# --- Step 2: Integration Test (Data Connectivity) ---
echo -e "\n🔎 Step 2: Testing Database Connectivity via API..."
# curl --fail will exit with non-zero if the response is 4xx or 5xx
if curl --fail -s "$BASE_URL/api/tasks" > /dev/null; then
  echo "✅ Database connectivity verified. API returned valid data."
else
  echo "❌ Integration Test Failed: Could not fetch items from database."
  exit 1
fi

echo -e "\n✨ All deployment verifications passed successfully!"
