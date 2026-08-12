# Deploying Ragnar Chatbot to AWS EC2

Guide for running the `{ragnar}` chatbot (build index + serve chat) on a single EC2 instance. Assumes the RHEL 9 requirements in [requirements.md](requirements.md) and the scripts in [scripts/](scripts/).

## 1. Launch the Instance

- AMI: RHEL 9 (or Amazon Linux 2023 as a substitute (adjust `dnf` package names as needed)
- Instance type: `t3.medium` (2 vCPU / 4 GB) for premier models; `t3.xlarge` or larger (8+ GB RAM) if running local Ollama models
- Storage: 20 GB gp3 minimum (10 GB for local Ollama models/index headroom, per requirements.md)
- Security group inbound rules:

| Port | Source | Purpose |
|------|--------|---------|
| 22   | your IP | SSH |
| 443  | 0.0.0.0/0 | HTTPS |
| 80   | 0.0.0.0/0 | HTTP (redirect to HTTPS) |

Do not open 11434 (Ollama) or 3838 (Shiny Server) publicly (proxy through nginx instead).

## 2. Connect and Verify Requirements

```bash
ssh -i your-key.pem ec2-user@<instance-public-ip>
```

Copy and run the verification script from requirements.md:

```bash
scp -i your-key.pem check-requirements.sh ec2-user@<instance-public-ip>:~
ssh -i your-key.pem ec2-user@<instance-public-ip> "./check-requirements.sh"
```

Install anything missing following requirements.md (R, compilation tools, system libraries).

## 3. Install R Packages and Project Files

```bash
sudo dnf install -y R-core R-devel gcc g++ gfortran make \
  openssl-devel libcurl-devel sqlite-devel zlib-devel \
  libstdc++-devel libbrotli-devel zstd-devel
```

```r
install.packages(c("ragnar", "duckdb", "httr2", "jsonlite", "cli"))
```

Copy this project and the book source to the instance:

```bash
scp -r -i your-key.pem . ec2-user@<instance-public-ip>:~/shragnar
ssh -i your-key.pem ec2-user@<instance-public-ip>
git clone https://github.com/mjfrigaard/shiny-app-pkgs.git ~/shragnar/shiny-app-pkgs
```

## 4. Store the API Key

```bash
sudo mkdir -p /etc/ragnar-chatbot
sudo tee /etc/ragnar-chatbot/env <<'EOF'
ANTHROPIC_API_KEY=your-key-here
EOF
sudo chmod 600 /etc/ragnar-chatbot/env
```

Never commit this file or the key to version control.

## 5. Build the Index

```bash
cd ~/shragnar
set -a; source /etc/ragnar-chatbot/env; set +a
Rscript scripts/01-build-index-premier.R
```

This produces `shiny-book-index.duckdb`. For a local Ollama deployment, install Ollama per `requirements.md` and run `scripts/03-build-index-local.R` instead.

## 6. Serve the Chatbot with Shiny Server

Install Shiny Server:

```bash
curl -o /tmp/shiny-server.rpm https://rstudio.com/shiny-server/downloads/shiny-server-latest.x86_64.rpm
sudo dnf install -y /tmp/shiny-server.rpm
```

Place your chat app (wrapping `scripts/02-chat-premier.R` logic) at `/srv/shiny-server/ragnar-chat/app.R`, and give it access to the API key via a systemd drop-in:

```bash
sudo mkdir -p /etc/systemd/system/shiny-server.service.d
sudo tee /etc/systemd/system/shiny-server.service.d/env.conf <<'EOF'
[Service]
EnvironmentFile=/etc/ragnar-chatbot/env
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now shiny-server
```

## 7. Reverse Proxy with nginx and TLS

```bash
sudo dnf install -y nginx certbot python3-certbot-nginx
```

`/etc/nginx/conf.d/ragnar-chat.conf`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3838;
        proxy_redirect http://127.0.0.1:3838/ $scheme://$host/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 20d;
        proxy_set_header Host $host;
    }
}
```

```bash
sudo systemctl enable --now nginx
sudo certbot --nginx -d yourdomain.com
```

## 8. Ongoing Operations

- Rebuild the index after book content changes: re-run `scripts/01-build-index-premier.R` (or `03-...` for local) and restart `shiny-server`.

- Back up `shiny-book-index.duckdb` to S3 rather than relying on instance storage:

```bash
aws s3 cp shiny-book-index.duckdb s3://your-bucket/ragnar/
```

- Monitor disk usage (`df -h /`) — see Storage Considerations in requirements.md for expected index size.
