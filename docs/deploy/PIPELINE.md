# Deploy Pipeline

## Flow

```
Local edit (public/index.html)
  ↓
feature branch → commit → push branch → PR merge to main
  ↓
GitHub Actions: .github/workflows/deploy.yml
  ↓  (~10s: checkout + scp)
VPS: /opt/services/nginx/html/dotsai.in/
  ↓  (~5s: nginx config validation + reload)
https://dotsai.in  LIVE ✅
```

**Total time: ~30–40 seconds**

## Files Deployed
```
public/*                  → /opt/services/nginx/html/dotsai.in/
deploy/nginx/default.conf → /opt/services/nginx/conf.d/default.conf
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
scp -r public/* root@72.62.229.16:/opt/services/nginx/html/dotsai.in/
scp deploy/nginx/default.conf root@72.62.229.16:/opt/services/nginx/conf.d/default.conf
ssh root@72.62.229.16 "docker exec nginx nginx -t && docker exec nginx nginx -s reload"
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
    location / { try_files $uri $uri/ $uri/index.html =404; }
    error_page 404 /404.html;
}
```
