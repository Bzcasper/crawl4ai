# Crawl4AI MCP Server

A **Model Context Protocol (MCP)** server for **Crawl4AI** that enables AI assistants to perform advanced web crawling and content extraction through standardized MCP tools.

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- Docker (for Redis)
- Git

### Installation

```bash
# Clone and setup
git clone <repository-url>
cd crawl4ai-mcp-server
chmod +x setup.sh
./setup.sh

# Start Redis
docker run -d -p 6379:6379 --name crawl4ai-redis redis:alpine

# Install Playwright browsers (requires sudo)
source venv/bin/activate
playwright install chromium

# Start the MCP server
./start_mcp.sh
```

## 📡 MCP Endpoints

- **Health**: `http://127.0.0.1:11234/health`
- **WebSocket**: `ws://127.0.0.1:11234/mcp/ws`
- **SSE**: `http://127.0.0.1:11234/mcp/sse`
- **Schema**: `http://127.0.0.1:11234/mcp/schema`
- **Playground**: `http://127.0.0.1:11234/playground`

## 🔧 Available MCP Tools

### 1. **`crawl`** - Multi-URL Web Crawling
```json
{
  "name": "crawl",
  "parameters": {
    "urls": ["https://example.com"],
    "browser_config": {},
    "crawler_config": {}
  }
}
```
**Returns**: Complete crawl results with HTML, links, metadata, markdown

### 2. **`md`** - Markdown Extraction
```json
{
  "name": "md",
  "parameters": {
    "url": "https://example.com",
    "f": "fit|raw|bm25|llm",
    "q": "search query",
    "c": "cache key"
  }
}
```
**Returns**: Filtered markdown content

### 3. **`html`** - Preprocessed HTML
```json
{
  "name": "html", 
  "parameters": {
    "url": "https://example.com"
  }
}
```
**Returns**: Cleaned HTML for schema extraction

### 4. **`screenshot`** - Page Screenshots
```json
{
  "name": "screenshot",
  "parameters": {
    "url": "https://example.com",
    "screenshot_wait_for": 2.0,
    "output_path": "/path/to/save.png"
  }
}
```
**Returns**: Base64 PNG or file path

### 5. **`pdf`** - PDF Generation
```json
{
  "name": "pdf",
  "parameters": {
    "url": "https://example.com",
    "output_path": "/path/to/save.pdf"
  }
}
```
**Returns**: Base64 PDF or file path

### 6. **`execute_js`** - JavaScript Execution
```json
{
  "name": "execute_js",
  "parameters": {
    "url": "https://example.com", 
    "scripts": [
      "await page.click('button#load-more')",
      "await page.waitForTimeout(2000)"
    ]
  }
}
```
**Returns**: Complete crawl result after JS execution

### 7. **`ask`** - Documentation Context
```json
{
  "name": "ask",
  "parameters": {
    "query": "How to extract links?",
    "context_type": "all|code|doc",
    "max_results": 20
  }
}
```
**Returns**: Relevant documentation and code examples

## 🔌 MCP Client Usage

### WebSocket Client Example
```python
import asyncio
import json
from mcp.client.websocket import websocket_client
from mcp.client.session import ClientSession

async def crawl_website():
    async with websocket_client("ws://127.0.0.1:11234/mcp/ws") as streams:
        read_stream, write_stream = streams
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            
            # Extract markdown
            result = await session.call_tool("md", {
                "url": "https://example.com",
                "f": "fit"
            })
            
            response = json.loads(result.content[0].text)
            print(f"Markdown: {response['markdown']}")

asyncio.run(crawl_website())
```

### Direct HTTP API
```bash
# Markdown extraction
curl -X POST "http://127.0.0.1:11234/md" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "f": "fit"}'

# Web crawling
curl -X POST "http://127.0.0.1:11234/crawl" \
  -H "Content-Type: application/json" \
  -d '{"urls": ["https://example.com"], "browser_config": {}, "crawler_config": {}}'

# Documentation search
curl "http://127.0.0.1:11234/ask?query=extract%20links&context_type=doc"
```

## 📁 Project Structure

```
crawl4ai-mcp-server/
├── deploy/docker/
│   ├── server.py              # Main FastAPI server
│   ├── mcp_bridge.py          # MCP protocol implementation  
│   ├── config.yml             # Server configuration
│   ├── .llm.env              # Environment variables
│   └── requirements.txt       # Dependencies
├── venv/                      # Python virtual environment
├── management-scripts/
│   ├── start_mcp.sh          # Start server
│   ├── test_mcp.sh           # Test connection
│   ├── status_mcp.sh         # Check status
│   └── example_client.py     # Example client
├── setup.sh                  # Installation script
├── docker-compose.yml        # Docker setup
└── README.md                 # This documentation
```

## ⚙️ Configuration

### Environment Variables
Edit `deploy/docker/.llm.env`:
```bash
# API Keys (optional)
OPENAI_API_KEY=your_key_here
DEEPSEEK_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
GROQ_API_KEY=your_key_here

# Server Configuration  
REDIS_HOST=localhost
REDIS_PORT=6379
SERVER_HOST=127.0.0.1
SERVER_PORT=11234
```

### Browser Configuration
```python
# Custom browser settings via MCP
result = await session.call_tool("crawl", {
    "urls": ["https://example.com"],
    "browser_config": {
        "headless": True,
        "viewport": {"width": 1920, "height": 1080}
    },
    "crawler_config": {
        "delay": 1.0,
        "timeout": 30
    }
})
```

## 🧪 Testing

### Health Check
```bash
curl http://127.0.0.1:11234/health
```

### MCP Schema
```bash
curl http://127.0.0.1:11234/mcp/schema | jq .
```

### Run Test Suite
```bash
./test_mcp.sh
```

## 🔍 Troubleshooting

### Common Issues

1. **Redis Connection Error**
   ```bash
   docker run -d -p 6379:6379 --name crawl4ai-redis redis:alpine
   ```

2. **Browser Not Found** 
   ```bash
   playwright install chromium
   ```

3. **Port Already in Use**
   ```bash
   lsof -i :11234
   ```

4. **MCP Connection Failed**
   ```bash
   ./status_mcp.sh
   ```

## 🌟 Production Deployment

### Docker Compose
```bash
docker-compose up --build
```

### Systemd Service
```bash
sudo systemctl enable crawl4ai-mcp
sudo systemctl start crawl4ai-mcp
```

### Reverse Proxy (Nginx)
```nginx
location /mcp/ {
    proxy_pass http://127.0.0.1:11234/mcp/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## 🎯 Use Cases

### Content Analysis Pipeline
1. **Crawl** competitor websites
2. **Extract** structured data and markdown
3. **Generate** reports using documentation context
4. **Create** PDFs and screenshots for analysis

### SEO Content Generation
1. **Analyze** top-ranking pages
2. **Extract** content patterns
3. **Query** best practices from documentation
4. **Generate** optimized content

### Web Monitoring
1. **Screenshot** pages for visual changes
2. **Execute** JavaScript to test interactions
3. **Extract** specific data points
4. **Generate** automated reports

## 📚 Integration Examples

### Claude Desktop MCP
```json
{
  "mcpServers": {
    "crawl4ai": {
      "command": "python",
      "args": ["/path/to/crawl4ai-mcp-server/deploy/docker/server.py"],
      "env": {
        "REDIS_HOST": "localhost"
      }
    }
  }
}
```

### API Gateway Integration
- Authentication and authorization
- Rate limiting and quotas  
- Monitoring and analytics
- Load balancing

## 🔗 Resources

- **Crawl4AI**: https://github.com/unclecode/crawl4ai
- **MCP Specification**: https://modelcontextprotocol.io/
- **FastAPI**: https://fastapi.tiangolo.com/
- **Playwright**: https://playwright.dev/

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 🆘 Support

- **Issues**: GitHub Issues
- **Documentation**: See `/docs` directory
- **Community**: GitHub Discussions

---

**🚀 Ready to power AI-driven web crawling and content extraction workflows!**
