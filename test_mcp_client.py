#!/usr/bin/env python3
"""
Test MCP client for Crawl4AI
"""
import asyncio
import json
from mcp.client.websocket import websocket_client
from mcp.client.session import ClientSession

async def test_mcp_tools():
    """Test various MCP tools"""
    print("🔌 Connecting to Crawl4AI MCP Server...")
    
    try:
        # Connect to the WebSocket endpoint
        async with websocket_client("ws://127.0.0.1:11234/mcp/ws") as streams:
            read_stream, write_stream = streams
            async with ClientSession(read_stream, write_stream) as session:
                await session.initialize()
                
                # List available tools
                tools = await session.list_tools()
                print(f"📋 Available tools: {[t.name for t in tools.tools]}")
                print()
                
                # Test 1: Ask tool - Get documentation context
                print("🔍 Test 1: Querying Crawl4AI documentation...")
                result = await session.call_tool("ask", {
                    "query": "How to extract markdown from a webpage?",
                    "context_type": "doc",
                    "max_results": 3
                })
                doc_response = json.loads(result.content[0].text)
                if "doc_results" in doc_response:
                    print(f"✅ Found {len(doc_response['doc_results'])} documentation sections")
                    if doc_response['doc_results']:
                        print(f"   Sample: {doc_response['doc_results'][0]['text'][:100]}...")
                else:
                    print("❌ No documentation results found")
                print()
                
                # Test 2: Markdown extraction
                print("🌐 Test 2: Extracting markdown from example.com...")
                result = await session.call_tool("md", {
                    "url": "https://example.com",
                    "f": "fit",
                    "q": None,
                    "c": "0"
                })
                md_response = json.loads(result.content[0].text)
                if md_response.get("success"):
                    print(f"✅ Markdown extracted: {len(md_response['markdown'])} characters")
                    print(f"   Preview: {md_response['markdown'][:150]}...")
                else:
                    print(f"❌ Markdown extraction failed: {md_response}")
                print()
                
                # Test 3: HTML extraction  
                print("📄 Test 3: Getting processed HTML...")
                result = await session.call_tool("html", {
                    "url": "https://example.com"
                })
                html_response = json.loads(result.content[0].text)
                if html_response.get("success"):
                    print(f"✅ HTML extracted: {len(html_response['html'])} characters")
                    print(f"   Preview: {html_response['html'][:100]}...")
                else:
                    print(f"❌ HTML extraction failed: {html_response}")
                print()
                
                # Test 4: Web crawling
                print("🕷️ Test 4: Crawling example.com...")
                result = await session.call_tool("crawl", {
                    "urls": ["https://example.com"],
                    "browser_config": {},
                    "crawler_config": {}
                })
                crawl_response = json.loads(result.content[0].text)
                if isinstance(crawl_response, list) and len(crawl_response) > 0:
                    crawl_result = crawl_response[0]
                    print(f"✅ Crawl completed successfully")
                    print(f"   URL: {crawl_result.get('url', 'Unknown')}")
                    print(f"   Status: {crawl_result.get('success', False)}")
                    print(f"   HTML length: {len(crawl_result.get('html', ''))}")
                    if 'links' in crawl_result:
                        link_count = sum(len(v) for v in crawl_result['links'].values())
                        print(f"   Links found: {link_count}")
                else:
                    print(f"❌ Crawl failed: {crawl_response}")
                print()
                
                print("🎉 MCP tool testing completed successfully!")
                
    except Exception as e:
        print(f"❌ Connection or tool execution failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_mcp_tools())
