#!/bin/bash
set -e

echo "=== RHEL 9 Ragnar Chatbot Requirements Check ==="
echo ""

# OS
echo "OS Version:"
cat /etc/redhat-release
echo ""

# Disk
echo "Disk Space (root):"
df -h / | tail -1
echo ""

# Memory
echo "Available Memory:"
free -h | grep Mem
echo ""

# R
echo "R Version:"
R --version | head -3
echo ""

# Compilation tools
echo "GCC:"
gcc --version | head -1
echo ""

# Python (optional)
echo "Python (if using Ollama):"
python3 --version 2>/dev/null || echo "Not installed (optional if using cloud models)"
echo ""

# Ollama (optional)
echo "Ollama (if using local models):"
ollama --version 2>/dev/null || echo "Not installed (optional if using cloud models)"
echo ""

# API keys
echo "Environment Variables:"
[ -n "$ANTHROPIC_API_KEY" ] && echo "✓ ANTHROPIC_API_KEY is set" || echo "✗ ANTHROPIC_API_KEY not set (required for Claude)"
[ -n "$OPENAI_API_KEY" ] && echo "✓ OPENAI_API_KEY is set" || echo "✗ OPENAI_API_KEY not set (required for OpenAI)"
echo ""

echo "=== Check Complete ==="
