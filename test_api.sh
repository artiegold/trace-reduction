#!/bin/bash

# Ticket Processor API Testing Script
# Usage: ./test_api.sh [base_url]

BASE_URL=${1:-"http://localhost:4000/api"}
TICKET_ID=""

echo "🎫 Ticket Processor API Testing Script"
echo "======================================"
echo "Base URL: $BASE_URL"
echo ""

# Function to make HTTP requests and display results
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo "📡 $description"
    echo "Request: $method $url"
    if [ ! -z "$data" ]; then
        echo "Data: $data"
    fi
    echo "---"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$BASE_URL$url")
    elif [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$url")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$BASE_URL$url")
    fi
    
    # Extract HTTP code and response body
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    body=$(echo "$response" | sed '$d')
    
    echo "Status: $http_code"
    echo "Response:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
    echo ""
    
    # Extract ticket ID from create response for later use
    if [ "$method" = "POST" ] && [ "$url" = "/tickets" ]; then
        TICKET_ID=$(echo "$body" | jq -r '.data.id' 2>/dev/null)
        if [ "$TICKET_ID" != "null" ] && [ ! -z "$TICKET_ID" ]; then
            echo "🎯 Created ticket ID: $TICKET_ID"
            echo ""
        fi
    fi
}

# Test 1: List all tickets
make_request "GET" "/tickets" "" "📋 List all tickets"

# Test 2: Create a new ticket
create_data='{
  "ticket": {
    "title": "API Test Ticket",
    "description": "This ticket was created via the API testing script",
    "priority": "medium",
    "assigned_to": ["test@example.com", "api@example.com"]
  }
}'
make_request "POST" "/tickets" "$create_data" "➕ Create a new ticket"

# Test 3: Get the created ticket (if we have an ID)
if [ ! -z "$TICKET_ID" ] && [ "$TICKET_ID" != "null" ]; then
    make_request "GET" "/tickets/$TICKET_ID" "" "👁️ Get the created ticket"
    
    # Test 4: Update the ticket
    update_data='{
      "ticket": {
        "title": "Updated API Test Ticket",
        "description": "This ticket was updated via the API testing script"
      }
    }'
    make_request "PUT" "/tickets/$TICKET_ID" "$update_data" "✏️ Update the ticket"
    
    # Test 5: Add an assignee
    assign_data='{"assignee": "newuser@example.com"}'
    make_request "PUT" "/tickets/$TICKET_ID/assign" "$assign_data" "👥 Add an assignee"
    
    # Test 6: Remove an assignee
    remove_data='{"assignee": "test@example.com"}'
    make_request "PUT" "/tickets/$TICKET_ID/remove_assignee" "$remove_data" "🚫 Remove an assignee"
    
    # Test 7: Resolve the ticket
    make_request "PUT" "/tickets/$TICKET_ID/resolve" "" "✅ Resolve the ticket"
    
    # Test 8: Close the ticket
    make_request "PUT" "/tickets/$TICKET_ID/close" "" "🔒 Close the ticket"
    
    # Test 9: Try to get the closed ticket
    make_request "GET" "/tickets/$TICKET_ID" "" "👁️ Get the closed ticket"
    
    # Test 10: Discard the ticket
    make_request "PUT" "/tickets/$TICKET_ID/discard" "" "🗑️ Discard the ticket"
else
    echo "❌ Could not extract ticket ID from create response. Skipping individual ticket tests."
    echo ""
fi

# Test 11: Filter tickets by status
make_request "GET" "/tickets?status=open" "" "🔍 Filter tickets by status (open)"

# Test 12: Try to get a non-existent ticket
make_request "GET" "/tickets/00000000-0000-0000-0000-000000000000" "" "❌ Get non-existent ticket (404 test)"

# Test 13: Try to create a ticket with invalid data
invalid_data='{
  "ticket": {
    "title": "",
    "description": "Invalid ticket",
    "priority": "invalid_priority"
  }
}'
make_request "POST" "/tickets" "$invalid_data" "❌ Create ticket with invalid data (422 test)"

echo "🎉 API Testing Complete!"
echo ""
echo "📊 Summary:"
echo "   - Tested all CRUD operations"
echo "   - Tested assignee management"
echo "   - Tested status transitions"
echo "   - Tested error handling"
echo ""
echo "🌐 Interactive API Documentation: $BASE_URL/../docs"
echo "📄 OpenAPI Specification: $BASE_URL/../docs/openapi.yaml"