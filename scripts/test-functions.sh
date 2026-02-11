#!/bin/bash
set -euo pipefail

BASE_URL=${APP_URL}

echo "🚀 Starting CRUD Functionality Tests..."

# 1. Test ADD (POST)
echo "🔎 Testing: Add Task..."
ADD_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"name": "Test Deployment Task"}' "$BASE_URL/api/tasks")
echo "✅ Task added successfully."

# 2. Get the ID of the task we just created
TASK_ID=$(curl -s "$BASE_URL/api/tasks" | grep -Po '"id":\K[0-9]+' | head -1)
echo "📍 Target Task ID: $TASK_ID"

# 3. Test MARK COMPLETE (PUT)
echo "🔎 Testing: Mark Complete..."
curl -s -X PUT "$BASE_URL/api/tasks/complete/$TASK_ID"
COMPLETED_STATUS=$(curl -s "$BASE_URL/api/tasks" | grep -Po "\"id\":$TASK_ID,\"name\":\"Test Deployment Task\",\"completed\":\K[0-1]")

if [ "$COMPLETED_STATUS" == "1" ]; then
    echo "✅ Task marked complete successfully."
else
    echo "❌ Failed to mark task complete."
    exit 1
fi

# 4. Test DELETE (DELETE)
echo "🔎 Testing: Delete Task..."
curl -s -X DELETE "$BASE_URL/api/tasks/$TASK_ID"
REMAINING=$(curl -s "$BASE_URL/api/tasks" | grep -c "\"id\":$TASK_ID" || true)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ Task deleted successfully."
else
    echo "❌ Failed to delete task."
    exit 1
fi

echo "🎉 All functionality tests passed!"
