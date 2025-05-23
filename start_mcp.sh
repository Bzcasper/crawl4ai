#!/bin/bash
set -e
echo "🚀 Starting Crawl4AI MCP Server..."

cd /home/bzcasper/Documents/crawl4ai
export PATH="$PWD/venv/bin:$PATH"

# Check Redis
if ! redis-cli ping > /dev/null 2>&1; then
    echo "🔴 Starting Redis..."
    redis-server --daemonize yes --port 6379 || {
        echo "❌ Failed to start Redis. Please start it manually:"
        echo "   redis-server --daemonize yes --port 6379"
        echo "   Or use Docker: docker run -d -p 6379:6379 redis:alpine"
        exit 1
    }
    sleep 2
fi

echo "✅ Redis is running"
echo "🌐 Starting MCP server on port 11235..."

cd deploy/docker
exec python server.py
