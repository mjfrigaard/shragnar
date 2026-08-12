# Requirements for Ragnar Chatbot Deployment (RHEL 9)

Full requirements list for running a `{ragnar}` chatbot on a RHEL 9 (Fedora) Linux server, including discovery commands to verify each requirement is met.

## Requirements Checklist

- [ ] RHEL 9 system with 2+ GB RAM and 2+ GB disk
- [ ] R 4.1.0+ installed
- [ ] `{ragnar}`, `{duckdb}`, and dependencies installed
- [ ] Compilation tools (gcc, make, openssl-devel)
- [ ] API key set (Anthropic OR OpenAI) OR Ollama installed and running
- [ ] Shiny Server installed (for interactive chatbot)
- [ ] Web server configured (nginx or Apache)
- [ ] Firewall rules configured
- [ ] SSL/TLS certificate installed
- [ ] `.env` or systemd environment file configured with API keys
- [ ] Initial index built and verified

## System Requirements

### Operating System

- RHEL 9 or compatible (Fedora, CentOS Stream 9)

Check OS version:
```bash
cat /etc/redhat-release
```

### Disk Space

- Minimum: 2 GB free space (for R, system packages, and a typical book index)

- Recommended: 10 GB free space (for multiple indices, logs, and headroom)

Check available disk space:

```bash
df -h /
df -h /home  # if running as non-root user
```

### Memory (RAM)

- Minimum: 2 GB RAM

- Recommended: 4-8 GB RAM (for reasonable embedding and chat performance)

- Local models (Ollama): 8 GB+ recommended

Check available RAM:

```bash
free -h
```

## Software Requirements

### R Installation

Minimum version: R 4.1.0

Install R on RHEL 9:

```bash
sudo dnf install -y epel-release
sudo dnf install -y R-core R-devel
```

Check R version:

```bash
R --version
```

### Required R Packages

Install all required packages:

```r
install.packages(c(
  "ragnar",
  "duckdb",
  "httr2",
  "jsonlite",
  "cli"
))
```

Verify package installation:

```r
library(ragnar)
library(duckdb)
packageVersion("ragnar")
packageVersion("duckdb")
```

### System Libraries (for R compilation)

Required by R and package compilation:

```bash
sudo dnf install -y gcc g++ gfortran make
sudo dnf install -y openssl-devel libcurl-devel sqlite-devel
```

Verify compilation tools:

```bash
gcc --version
make --version
```

### System Libraries (for R packages)

Additional system libraries required by `{ragnar}`, `{duckdb}`, and dependencies:

#### Core dependencies

```bash
sudo dnf install -y libcurl-devel
sudo dnf install -y openssl-devel
sudo dnf install -y zlib-devel
```

#### DuckDB-specific

`{duckdb}` is a columnar database engine requiring:

```bash
sudo dnf install -y libstdc++-devel
```

#### Additional compression and encoding libraries

For vector operations and embedding:

```bash
sudo dnf install -y libbrotli-devel
sudo dnf install -y zstd-devel
```

#### Complete library installation for ragnar stack

Install all required system libraries at once:

```bash
sudo dnf install -y \
  libcurl-devel \
  openssl-devel \
  zlib-devel \
  libstdc++-devel \
  libbrotli-devel \
  zstd-devel
```

Verify libraries are installed:

```bash
ldconfig -p | grep libcurl
ldconfig -p | grep libssl
ldconfig -p | grep libz
```

### Python (for Ollama support, optional)

If using local models via Ollama, Python 3.8+ is required:

```bash
python3 --version
```

Install Python if needed:

```bash
sudo dnf install -y python3 python3-pip
```

### Ollama (for local models only)

Required if deploying local embedding and chat models; skip if using Claude/OpenAI.

Install Ollama:

```bash
# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Or manual installation
sudo dnf install -y ollama
```

Verify Ollama installation:

```bash
ollama --version
```

Pull required models:

```bash
ollama pull nomic-embed-text    # embedding model
ollama pull mistral             # chat model (or your choice)
```

Verify models are available:

```bash
ollama list
```

## API Keys and Credentials

### For Premier Models (Claude/OpenAI)

#### Anthropic Claude

Required if using `embed_anthropic()` or Claude for chat.

1. Create account at https://console.anthropic.com/   
2. Generate API key   
3. Store as environment variable:   

```bash
export ANTHROPIC_API_KEY="your-key-here"
```

Verify key is set:

```bash
echo $ANTHROPIC_API_KEY
curl https://api.anthropic.com/v1/models \
  -H "x-api-key: $ANTHROPIC_API_KEY" | head -c 100
```

#### OpenAI GPT

Required if using OpenAI models for embedding or chat.

1. Create account at https://platform.openai.com/   
2. Generate API key   
3. Store as environment variable:   

```bash
export OPENAI_API_KEY="your-key-here"
```

Verify key is set:

```bash
echo $OPENAI_API_KEY
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" | head -c 100
```

### For Local Models (Ollama)

No API keys required. Verify Ollama server is running:

```bash
curl http://localhost:11434/api/tags
```

## Deployment and Serving

### Shiny Server (for interactive chatbot)

Install Shiny Server to serve the chatbot as a web application:

```bash
sudo dnf install -y curl
curl https://rstudio.com/shiny-server/downloads/shiny-server-latest.x86_64.rpm -o /tmp/shiny-server.rpm
sudo dnf install -y /tmp/shiny-server.rpm
```

Verify Shiny Server:

```bash
shiny-server --version
sudo systemctl status shiny-server
```

### Quarto (for static documentation with chat widget)

Install Quarto for publishing the book with integrated chat:

```bash
curl -LO https://quarto.org/download/latest/quarto-linux-x86_64.deb
sudo dnf install -y ./quarto-*.rpm
```

Verify Quarto:

```bash
quarto --version
```

### Web Server (nginx or Apache)

If serving a Shiny app or static Quarto site:

```bash
sudo dnf install -y nginx
# or
sudo dnf install -y httpd
```

Verify web server:

```bash
sudo systemctl status nginx
# or
sudo systemctl status httpd
```

## Network Requirements

### Outbound Connectivity (for premier models)

Required if using Claude or OpenAI:   
- Anthropic API: `https://api.anthropic.com` (port 443)   
- OpenAI API: `https://api.openai.com` (port 443)   

Test connectivity:

```bash
curl -I https://api.anthropic.com
curl -I https://api.openai.com
```

### Localhost Ports (for local Ollama)

If running Ollama locally:    
- Ollama server: `localhost:11434` (default)    

Test local Ollama:

```bash
curl http://localhost:11434/api/tags
```

### Web Server Ports

For public chatbot access:    
- HTTP: port 80   
- HTTPS: port 443 (recommended)   

Check if ports are open:

```bash
sudo netstat -tlnp | grep LISTEN
# or
sudo ss -tlnp | grep LISTEN
```

## Quick Verification Script

Run this script to verify all core requirements are met:

```bash
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
```

Save as `check-requirements.sh` and run:

```bash
chmod +x check-requirements.sh
./check-requirements.sh
```

## Storage Considerations

### DuckDB Index Size

The embedded index size depends on your documentation:    
- Small book (100 pages): ~50-100 MB    
- Medium book (300 pages): ~150-300 MB    
- Large book (500+ pages): ~400-800 MB    

Rough calculation: ~1 MB per 2-3 pages    

Check index size:

```bash
ls -lh shiny-book-index.duckdb
du -sh ./
```

### Log and Temporary Files

Allocate additional space for:    
- Application logs: ~50 MB per month (depends on query volume)    
- Temporary files: ~100 MB per rebuild    
- Session data (Shiny): ~10-100 MB depending on active sessions   

## Deployment Path Selection

### Premier Models (Claude/OpenAI)

- Requires: R, API key, network access    
- Does not require: Ollama, Python, extra disk    
- Best for: Published chatbots, high quality responses, low maintenance   

### Local Models (Ollama)

- Requires: R, Python, Ollama, 8+ GB RAM, ~10 GB disk   
- Does not require: API keys    
- Best for: Private deployments, no API costs, offline usage    

## Security Considerations

### API Key Management

Never commit API keys to version control:

```bash
# Use .env file (not version controlled)
echo "ANTHROPIC_API_KEY=your-key" > .env
source .env

# Or use systemd environment file
sudo nano /etc/default/ragnar-chatbot
# Add: ANTHROPIC_API_KEY=your-key
```

### Firewall Rules

Restrict access to Ollama server (if local):

```bash
sudo firewall-cmd --add-port=11434/tcp --permanent  # Allow only local
sudo firewall-cmd --reload
```

Restrict Ollama to localhost only:

```bash
# In Ollama config or startup
export OLLAMA_HOST=127.0.0.1:11434
```

### SSL/TLS for Web Server

Always use HTTPS for public deployments:

```bash
# Using Let's Encrypt with nginx
sudo dnf install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com
```