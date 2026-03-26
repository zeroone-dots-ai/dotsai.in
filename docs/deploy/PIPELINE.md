# Deploy Pipeline

## Flow

```
Local edit (public/index.html)
  ↓
git commit + push to main branch
  ↓
GitHub Actions: .github/workflows/deploy.yml
  ↓  (~10s: checkout + scp)
VPS: /opt/services/nginx/html/dotsai.in/
  ↓  (~5s: nginx reload)
https://dotsai.in  LIVE ✅
```

**Total time: ~30–40 seconds**

## Files Deployed
```
public/index.html   → /opt/services/nginx/html/dotsai.in/index.html
public/robots.txt   → /opt/services/nginx/html/dotsai.in/robots.txt
public/sitemap.xml  → /opt/services/nginx/html/dotsai.in/sitemap.xml
public/llms.txt     → /opt/services/nginx/html/dotsai.in/llms.txt
```

## GitHub Secrets
| Secret | Description |
|--------|-------------|
| `VPS_HOST` | 72.62.229.16 |
| `VPS_USER` | root |
| `VPS_SSH_KEY` | ed25519 deploy key (generated 2026-03-26) |

> Secrets are in GitHub → zeroone-dots-ai/dotsai.in → Settings → Secrets

## Checking Deploy Status
```bash
# Via GitHub CLI
gh run list --repo zeroone-dots-ai/dotsai.in --limit 5

# Verify live site
curl -sk https://dotsai.in | grep '<title>'
```

## Manual Fallback (if Actions fails)
```bash
scp public/index.html root@72.62.229.16:/opt/services/nginx/html/dotsai.in/index.html
ssh root@72.62.229.16 "docker exec nginx nginx -s reload"
```

## VPS Nginx Config
File: `/opt/services/nginx/conf.d/default.conf`
```nginx
server {
    listen 443 ssl;
    server_name dotsai.in;
    root /usr/share/nginx/html/dotsai.in;
    index index.html;
    gzip on;
    location / { try_files $uri $uri/ /index.html; }
}
```
