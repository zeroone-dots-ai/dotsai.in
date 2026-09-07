#!/usr/bin/env bash
# Run on the VPS after payload is at /tmp/msme-blog-payload/
# Finds the nginx document root that actually serves dotsai.in (host bind
# mounts AND docker overlay copies), copies the three MSME posts + blog
# index there, patches sitemap/llms, reloads nginx.
set -euo pipefail

PAYLOAD="${1:-/tmp/msme-blog-payload}"
MARKER="ai-for-textile-industry-surat"
NEEDLE_SITEMAP="ai-for-textile-industry-surat"

echo "=== payload ==="
ls -la "$PAYLOAD" "$PAYLOAD"/*/index.html 2>/dev/null || ls -la "$PAYLOAD"

echo "=== 443 / 80 listeners ==="
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || true) | grep -E ':443|:80' || true

echo "=== host nginx version ==="
nginx -v 2>&1 || true
command -v nginx || true

echo "=== systemd web units ==="
systemctl list-units --type=service --all 2>/dev/null | grep -iE 'nginx|caddy|httpd|traefik|dotsai' || true

echo "=== /opt/apps/dotsai-in ==="
ls -la /opt/apps/dotsai-in 2>/dev/null || true
ls -la /opt/apps/dotsai-in/public/blog 2>/dev/null || true
find /opt/apps/dotsai-in -maxdepth 3 \( -iname '*compose*' -o -iname 'Dockerfile*' -o -iname '*nginx*' -o -iname 'Caddyfile' \) 2>/dev/null || true

echo "=== docker ps (all) ==="
if command -v docker >/dev/null; then
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' || true
  echo "=== docker mounts (nginx/dotsai/web/proxy) ==="
  docker ps --format '{{.Names}}' | while read -r c; do
    docker inspect --format "$c image={{.Config.Image}}
  ports={{json .NetworkSettings.Ports}}
  mounts={{range .Mounts}}{{.Source}}->{{.Destination}} ({{.Type}}); {{end}}" "$c" 2>/dev/null || true
  done
fi

ROOTS=()
add_root() {
  local r="$1"
  [ -n "$r" ] || return 0
  r="${r%/}"
  [ -d "$r" ] || return 0
  local e
  for e in "${ROOTS[@]:-}"; do
    [ "$e" = "$r" ] && return 0
  done
  ROOTS+=("$r")
}

echo "=== textile dirs on host ==="
mapfile -t TEXTILE_DIRS < <(find /opt /usr/share/nginx /var/www /home /srv /data /root \
  /var/lib/docker/volumes -type d -name "$MARKER" 2>/dev/null || true)
printf '%s\n' "${TEXTILE_DIRS[@]:-(none)}"

for d in "${TEXTILE_DIRS[@]:-}"; do
  add_root "$(dirname "$(dirname "$d")")"
done

echo "=== Chubbo font copies (live-site fingerprint) ==="
mapfile -t CHUBBO < <(find /opt /usr/share/nginx /var/www /home /srv /data -name 'Chubbo-Variable.woff2' 2>/dev/null | head -30 || true)
printf '%s\n' "${CHUBBO[@]:-(none)}"
for f in "${CHUBBO[@]:-}"; do
  r="$(dirname "$(dirname "$(dirname "$f")")")"
  if [ -d "$r/blog/$MARKER" ] || grep -q "$NEEDLE_SITEMAP" "$r/sitemap.xml" 2>/dev/null; then
    echo "chubbo live root $r"
    add_root "$r"
  else
    echo "chubbo skip $r (no textile blog/sitemap)"
  fi
done

echo "=== sitemap.xml copies that mention the textile post ==="
mapfile -t SITEMAPS < <(find /opt /usr/share/nginx /var/www /home /srv /data /root \
  /var/lib/docker/volumes -name sitemap.xml 2>/dev/null | while read -r f; do
    grep -q "$NEEDLE_SITEMAP" "$f" 2>/dev/null && echo "$f"
  done || true)
printf '%s\n' "${SITEMAPS[@]:-(none)}"
for f in "${SITEMAPS[@]:-}"; do
  add_root "$(dirname "$f")"
done

echo "=== nginx confs naming dotsai.in (host) ==="
mapfile -t CONFS < <(grep -Rsl "server_name dotsai.in" /etc/nginx /opt/services/nginx /opt/apps /opt/nginx 2>/dev/null || true)
printf '%s\n' "${CONFS[@]:-(none)}"
for conf in "${CONFS[@]:-}"; do
  [ -f "$conf" ] || continue
  echo "--- $conf ---"
  grep -nE "server_name|root |alias |proxy_pass|include " "$conf" | head -60
  # naive parse: last root seen after a dotsai.in server_name
  root=$(awk '
    /server_name[[:space:]].*dotsai\.in/ {s=1}
    s && /[[:space:]]root[[:space:]]/ { gsub(/[;";]/,"",$2); print $2 }
    s && /^[[:space:]]*}/ {s=0}
  ' "$conf")
  while IFS= read -r r; do
    [ -n "$r" ] && echo "parsed root=$r" && add_root "$r"
  done <<< "$root"
done

if command -v nginx >/dev/null; then
  echo "=== nginx -T dotsai.in blocks (host) ==="
  nginx -T 2>/dev/null | awk '
    /server_name[[:space:]].*dotsai\.in/ {p=1}
    p {print}
    p && /^[[:space:]]*}/ {c++; if(c>0 && $0 ~ /^}/) {p=0; c=0}}
  ' | head -80 || true
fi

DOCKER_TARGETS=()  # container:path
add_docker() {
  local t="$1"
  local e
  for e in "${DOCKER_TARGETS[@]:-}"; do
    [ "$e" = "$t" ] && return 0
  done
  DOCKER_TARGETS+=("$t")
}

if command -v docker >/dev/null; then
  echo "=== docker: search common html roots + nginx -T ==="
  while read -r c; do
    [ -n "$c" ] || continue
    for p in \
      /usr/share/nginx/html \
      /usr/share/nginx/html/dotsai.in \
      /var/www/html \
      /var/www/dotsai.in \
      /app/public \
      /app \
      /data \
      /www \
      /html \
      /opt/apps/dotsai-in/public; do
      if docker exec "$c" test -d "$p/blog/$MARKER" 2>/dev/null; then
        echo "FOUND $c:$p (textile dir)"
        add_docker "$c:$p"
        # only treat as a host root if the same path exists on the host
        [ -d "$p/blog/$MARKER" ] && add_root "$p"
      elif docker exec "$c" test -f "$p/sitemap.xml" 2>/dev/null && \
           docker exec "$c" grep -q "$NEEDLE_SITEMAP" "$p/sitemap.xml" 2>/dev/null; then
        echo "FOUND $c:$p (sitemap)"
        add_docker "$c:$p"
        [ -f "$p/sitemap.xml" ] && add_root "$p"
      fi
    done
    if docker exec "$c" sh -c 'command -v nginx >/dev/null' 2>/dev/null; then
      echo "--- nginx -T in $c (dotsai.in) ---"
      docker exec "$c" nginx -T 2>/dev/null | awk '
        /server_name[[:space:]].*dotsai\.in/ {p=1}
        p {print}
        p && /^[[:space:]]*}/ {if($0 ~ /^[[:space:]]*}/) n++; if(n>=1 && $0 ~ /^}/ ){p=0}}
      ' | head -80 || true
      mapfile -t parsed_roots < <(docker exec "$c" nginx -T 2>/dev/null | awk '
        /server_name[[:space:]].*dotsai\.in/ {s=1}
        s && /[[:space:]]root[[:space:]]/ { gsub(/[;";]/,"",$2); print $2 }
        s && /^[[:space:]]*}/ {s=0}
      ' || true)
      for r in "${parsed_roots[@]:-}"; do
        [ -n "$r" ] || continue
        echo "container $c parsed root=$r"
        if docker exec "$c" test -d "$r" 2>/dev/null; then
          add_docker "$c:$r"
        fi
        [ -d "$r/blog/$MARKER" ] && add_root "$r"
      done
    fi
  done < <(docker ps --format '{{.Names}}')
fi

echo "=== fingerprint served textile vs on-disk copies ==="
SERVED_BODY=$(mktemp)
curl -sk --resolve dotsai.in:443:127.0.0.1 --resolve dotsai.in:80:127.0.0.1 \
  "https://dotsai.in/blog/$MARKER/" -o "$SERVED_BODY" || \
curl -s --resolve dotsai.in:80:127.0.0.1 \
  "http://dotsai.in/blog/$MARKER/" -o "$SERVED_BODY" || true
SERVED_MD5=$(md5sum "$SERVED_BODY" 2>/dev/null | awk '{print $1}')
echo "served md5=$SERVED_MD5 bytes=$(wc -c < "$SERVED_BODY")"
for d in "${TEXTILE_DIRS[@]:-}"; do
  f="$d/index.html"
  [ -f "$f" ] || continue
  m=$(md5sum "$f" | awk '{print $1}')
  echo "  $m  $f"
  if [ -n "$SERVED_MD5" ] && [ "$m" = "$SERVED_MD5" ]; then
    echo "  ^^ MATCHES served content — this is a live document root"
    add_root "$(dirname "$(dirname "$d")")"
  fi
done
if command -v docker >/dev/null && [ -n "$SERVED_MD5" ]; then
  while read -r c; do
    [ -n "$c" ] || continue
    for p in /usr/share/nginx/html /usr/share/nginx/html/dotsai.in /var/www/html /app/public; do
      m=$(docker exec "$c" md5sum "$p/blog/$MARKER/index.html" 2>/dev/null | awk '{print $1}' || true)
      if [ -n "$m" ]; then
        echo "  $m  docker:$c:$p/blog/$MARKER/index.html"
        if [ "$m" = "$SERVED_MD5" ]; then
          echo "  ^^ MATCHES served content"
          add_docker "$c:$p"
        fi
      fi
    done
  done < <(docker ps --format '{{.Names}}')
fi
rm -f "$SERVED_BODY"

if [ ${#ROOTS[@]} -eq 0 ] && [ ${#DOCKER_TARGETS[@]} -eq 0 ]; then
  echo "ERROR: no document roots found" >&2
  exit 1
fi

install_into() {
  local ROOT="$1"
  echo ">> host $ROOT"
  mkdir -p "$ROOT/blog/private-ai-for-indian-msmes" \
           "$ROOT/blog/tally-automation-ai-msme" \
           "$ROOT/blog/whatsapp-order-automation-msme"
  cp -f "$PAYLOAD/private-ai-for-indian-msmes/index.html" "$ROOT/blog/private-ai-for-indian-msmes/index.html"
  cp -f "$PAYLOAD/tally-automation-ai-msme/index.html" "$ROOT/blog/tally-automation-ai-msme/index.html"
  cp -f "$PAYLOAD/whatsapp-order-automation-msme/index.html" "$ROOT/blog/whatsapp-order-automation-msme/index.html"
  cp -f "$PAYLOAD/index.html" "$ROOT/blog/index.html"
  python3 /tmp/patch-live-blog-seo.py "$ROOT" || echo "WARN: sitemap/llms patch failed for $ROOT"
  ls -la "$ROOT/blog" | head -20
}

echo "=== deploying into host roots ==="
if ((${#ROOTS[@]})); then
  printf '  %s\n' "${ROOTS[@]}"
  for ROOT in "${ROOTS[@]}"; do
    install_into "$ROOT"
  done
else
  echo "  (none)"
fi

echo "=== deploying into docker targets ==="
if ((${#DOCKER_TARGETS[@]})); then
  printf '  %s\n' "${DOCKER_TARGETS[@]}"
  for t in "${DOCKER_TARGETS[@]}"; do
    c="${t%%:*}"
    ROOT="${t#*:}"
    echo ">> docker $c:$ROOT"
    docker exec "$c" mkdir -p \
      "$ROOT/blog/private-ai-for-indian-msmes" \
      "$ROOT/blog/tally-automation-ai-msme" \
      "$ROOT/blog/whatsapp-order-automation-msme"
    docker cp "$PAYLOAD/private-ai-for-indian-msmes/index.html" \
      "$c:$ROOT/blog/private-ai-for-indian-msmes/index.html"
    docker cp "$PAYLOAD/tally-automation-ai-msme/index.html" \
      "$c:$ROOT/blog/tally-automation-ai-msme/index.html"
    docker cp "$PAYLOAD/whatsapp-order-automation-msme/index.html" \
      "$c:$ROOT/blog/whatsapp-order-automation-msme/index.html"
    docker cp "$PAYLOAD/index.html" "$c:$ROOT/blog/index.html"
    docker cp /tmp/patch-live-blog-seo.py "$c:/tmp/patch-live-blog-seo.py"
    docker exec "$c" python3 /tmp/patch-live-blog-seo.py "$ROOT" 2>/dev/null \
      || docker exec "$c" python /tmp/patch-live-blog-seo.py "$ROOT" 2>/dev/null \
      || echo "WARN: could not patch sitemap inside $c (will rely on host copy if bind-mounted)"
  done
else
  echo "  (none)"
fi

echo "=== reload nginx ==="
if command -v nginx >/dev/null; then
  nginx -s reload && echo "host nginx reloaded" || echo "host nginx reload failed"
fi
if command -v docker >/dev/null; then
  while read -r c; do
    [ -n "$c" ] || continue
    if docker exec "$c" sh -c 'command -v nginx >/dev/null' 2>/dev/null; then
      echo "reload $c"
      docker exec "$c" nginx -s reload 2>/dev/null || docker exec "$c" kill -HUP 1 2>/dev/null || true
    fi
  done < <(docker ps --format '{{.Names}}')
fi

echo "=== local curl (SNI dotsai.in → 127.0.0.1) ==="
for url in \
  "https://dotsai.in/blog/private-ai-for-indian-msmes/" \
  "https://dotsai.in/blog/tally-automation-ai-msme/" \
  "https://dotsai.in/blog/whatsapp-order-automation-msme/" \
  "https://dotsai.in/blog/" \
  "https://dotsai.in/sitemap.xml"; do
  code=$(curl -sk --resolve dotsai.in:443:127.0.0.1 -o /tmp/msme-local-body -w "%{http_code}" "$url" || echo err)
  echo "$code $url"
  head -c 180 /tmp/msme-local-body; echo
done

# Fail the job if localhost still 404s — that means we still missed the served root.
LOCAL_CODE=$(curl -sk --resolve dotsai.in:443:127.0.0.1 -o /dev/null -w "%{http_code}" \
  "https://dotsai.in/blog/private-ai-for-indian-msmes/" || echo 000)
if [ "$LOCAL_CODE" != "200" ]; then
  echo "ERROR: local origin still $LOCAL_CODE for new post — document root not found" >&2
  echo "=== extra: ls /opt/apps ==="
  ls -la /opt/apps 2>/dev/null || true
  echo "=== extra: find Chubbo font (live site fingerprint) ==="
  find /opt /usr/share/nginx /var/www /home -name 'Chubbo-Variable.woff2' 2>/dev/null | head -20 || true
  exit 1
fi
echo "local origin OK"
