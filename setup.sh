#!/bin/bash
set -e

# Crawl4AI MCP Server Setup Script
# Automated installation and configuration

echo "🚀 Setting up Crawl4AI MCP Server..."

# Check prerequisites
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists python3; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

if ! command_exists git; then
    echo "❌ Git is required but not installed."
    exit 1
fi

# Create virtual environment
echo "🐍 Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install the package in editable mode
echo "📦 Installing Crawl4AI..."
pip install -e .

# Install server dependencies
echo "🔌 Installing MCP server dependencies..."
pip install -r deploy/docker/requirements.txt

# Install MCP client tools
echo "🧩 Installing MCP client..."
pip install "mcp[tools]" "mcp[cli]"

# Install Playwright (browsers need to be installed separately)
echo "🌐 Installing Playwright..."
pip install playwright
echo "⚠️ Playwright browsers need to be installed manually:"
echo "   playwright install chromium"

# Setup configuration
echo "⚙️ Setting up configuration..."
cd deploy/docker

if [ ! -f ".llm.env" ]; then
    cat > .llm.env << 'EOF'
# API Keys for LLM services (optional)
OPENAI_API_KEY=
DEEPSEEK_API_KEY=
ANTHROPIC_API_KEY=
GROQ_API_KEY=
TOGETHER_API_KEY=
MISTRAL_API_KEY=
GEMINI_API_TOKEN=

# Server Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
SERVER_HOST=127.0.0.1
SERVER_PORT=11234
EOF
    echo "📝 Created .llm.env file"
fi

cd ../..

# Create management scripts
echo "📝 Creating management scripts..."

# Start script
cat > start_mcp.sh << 'EOF'
#!/bin/bash
set -e
echo "🚀 Starting Crawl4AI MCP Server..."

cd "$(dirname "$0")"
export PATH="$PWD/venv/bin:$PATH"

# Check Redis
if ! command -v redis-cli >/dev/null 2>&1; then
    echo "⚠️ Redis CLI not found. Using Docker Redis..."
    if ! docker ps | grep -q crawl4ai-redis; then
        echo "🔴 Starting Redis with Docker..."
        docker run -d -p 6379:6379 --name crawl4ai-redis redis:alpine
        sleep 3
    fi
elif ! redis-cli ping > /dev/null 2>&1; then
    echo "🔴 Starting Redis..."
    if command -v redis-server >/dev/null 2>&1; then
        redis-server --daemonize yes --port 6379
        sleep 2
    else
        echo "❌ Redis not available. Please start Redis or use Docker:"
        echo "   docker run -d -p 6379:6379 --name crawl4ai-redis redis:alpine"
        exit 1
    fi
fi

echo "✅ Redis is running"
echo "🌐 Starting MCP server on port 11234..."

cd deploy/docker
exec python server.py
EOF
chmod +x start_mcp.sh

# Test script
cat > test_mcp.sh << 'EOF'
#!/bin/bash
set -e
cd "$(dirname "$0")"
export PATH="$PWD/venv/bin:$PATH"

echo "🧪 Testing Crawl4AI MCP Server..."

# Check if server is running
if ! curl -s http://127.0.0.1:11234/health > /dev/null; then
    echo "❌ Server is not running. Start it with: ./start_mcp.sh"
    exit 1
fi

echo "✅ Server is running"

# Test health endpoint
echo "🔍 Health Check:"
curl -s http://127.0.0.1:11234/health | python -m json.tool

echo ""
echo "📋 Available Tools:"
curl -s http://127.0.0.1:11234/mcp/schema | python -c "
import sys, json
data = json.load(sys.stdin)
tools = data.get('tools', [])
print(f'Found {len(tools)} MCP tools:')
for tool in tools:
    name = tool.get('name', 'Unknown')
    desc = tool.get('description', 'No description')[:60]
    print(f'  • {name}: {desc}...')
"

echo ""
echo "🧪 Testing markdown extraction..."
curl -s -X POST "http://127.0.0.1:11234/md" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "f": "fit"}' | \
  python -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success'):
    print(f'✅ Markdown extracted: {len(data[\"markdown\"])} characters')
else:
    print('❌ Markdown extraction failed')
"

echo ""
echo "🎉 MCP server testing completed!"
EOF
chmod +x test_mcp.sh

# Status script
cat > status_mcp.sh << 'EOF'
#!/bin/bash
echo "🔍 Crawl4AI MCP Server Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📡 Server Health:"
if curl -s http://127.0.0.1:11234/health > /dev/null; then
    curl -s http://127.0.0.1:11234/health | python -m json.tool
    echo "✅ Server is running"
else
    echo "❌ Server is not responding"
fi

echo ""
echo "🔴 Redis Status:"
if command -v redis-cli >/dev/null 2>&1 && redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is running"
    redis-cli info server | grep "redis_version\|uptime_in_seconds" || echo "Redis info unavailable"
elif docker ps | grep -q crawl4ai-redis; then
    echo "✅ Redis is running (Docker)"
    docker exec crawl4ai-redis redis-cli info server | grep "redis_version\|uptime_in_seconds" || echo "Redis info unavailable"
else
    echo "❌ Redis is not running"
fi

echo ""
echo "🔧 Process Status:"
ps aux | grep -E "(python.*server\.py|redis-server)" | grep -v grep || echo "No relevant processes found"
EOF
chmod +x status_mcp.sh

# Example client
cat > example_client.py << 'EOF'
#!/usr/bin/env python3
"""
Example MCP client for Crawl4AI
Demonstrates how to use the various MCP tools
"""
import asyncio
import json
from mcp.client.websocket import websocket_client
from mcp.client.session import ClientSession

async def demonstrate_tools():
    """Demonstrate MCP client usage with all tools"""
    print("🔌 Connecting to Crawl4AI MCP Server...")
    
    try:
        async with websocket_client("ws://127.0.0.1:11234/mcp/ws") as streams:
            read_stream, write_stream = streams
            async with ClientSession(read_stream, write_stream) as session:
                await session.initialize()
                
                # List available tools
                tools = await session.list_tools()
                print(f"📋 Available tools: {[t.name for t in tools.tools]}")
                print()
                
                # Demo 1: Documentation search
                print("📚 Searching Crawl4AI documentation...")
                result = await session.call_tool("ask", {
                    "query": "How to extract structured data?",
                    "context_type": "doc",
                    "max_results": 2
                })
                doc_response = json.loads(result.content[0].text)
                if "doc_results" in doc_response:
                    print(f"✅ Found {len(doc_response['doc_results'])} documentation sections")
                
                # Demo 2: Markdown extraction with filtering
                print("\n🌐 Extracting markdown with FIT filtering...")
                result = await session.call_tool("md", {
                    "url": "https://example.com",
                    "f": "fit"
                })
                md_response = json.loads(result.content[0].text)
                if md_response.get("success"):
                    print(f"✅ Markdown: {md_response['markdown'][:100]}...")
                
                # Demo 3: Comprehensive web crawling
                print("\n🕷️ Performing comprehensive crawl...")
                result = await session.call_tool("crawl", {
                    "urls": ["https://example.com"],
                    "browser_config": {},
                    "crawler_config": {}
                })
                crawl_response = json.loads(result.content[0].text)
                if crawl_response.get("success"):
                    crawl_result = crawl_response["results"][0]
                    print(f"✅ Crawl successful:")
                    print(f"   📄 HTML: {len(crawl_result['html'])} chars")
                    print(f"   🔗 Links: {len(crawl_result['links']['external'])} external")
                    print(f"   📋 Title: {crawl_result['metadata']['title']}")
                
                print("\n🎉 All demonstrations completed successfully!")
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(demonstrate_tools())
EOF
chmod +x example_client.py

echo ""
echo "✅ Crawl4AI MCP Server setup completed!"
echo ""
echo "🎯 Next Steps:"
echo "  1. Install Redis:"
echo "     • System: sudo apt install redis-server"
echo "     • Docker: docker run -d -p 6379:6379 --name crawl4ai-redis redis:alpine"
echo ""
echo "  2. Install Playwright browsers:"
echo "     source venv/bin/activate && playwright install chromium"
echo ""
echo "  3. Add API keys (optional):"
echo "     edit deploy/docker/.llm.env"
echo ""
echo "  4. Start the server:"
echo "     ./start_mcp.sh"
echo ""
echo "  5. Test the setup:"
echo "     ./test_mcp.sh"
echo ""
echo "🚀 Ready to use Crawl4AI MCP tools!"
