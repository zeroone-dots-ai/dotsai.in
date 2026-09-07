#!/usr/bin/env bash
# Run on the VPS after payload is at /tmp/msme-blog-payload/
# Live dotsai.in is reverse-proxied (edge nginx → dotsai-in container).
# Files are baked into the image (no bind mount), so we docker-cp into the
# running container AND sync /opt/apps/dotsai-in/public for the next rebuild.
set -eu
# Do not use pipefail: grep|head on large confs exits 141.

PAYLOAD="${1:-/tmp/msme-blog-payload}"
MARKER="ai-for-textile-industry-surat"

echo "=== payload ==="
ls -la "$PAYLOAD" "$PAYLOAD"/*/index.html

echo "=== live proxy config (dotsai.in) ==="
CONF=/opt/services/nginx/conf.d/default.conf
if [ -f "$CONF" ]; then
  grep -nE 'server_name dotsai\.in|up_dotsai|dots-ai-website|dotsai-in|proxy_pass|set \$up' "$CONF" | head -40
  echo "----- server block excerpt -----"
  awk '
    /server_name[[:space:]]+dotsai\.in([ ;]|$)/ {p=1}
    p {print}
    p && /^}/ {exit}
  ' "$CONF" | head -80
fi

echo "=== /opt/apps/dotsai-in compose/nginx ==="
sed -n '1,80p' /opt/apps/dotsai-in/nginx.conf 2>/dev/null || true
sed -n '1,80p' /opt/apps/dotsai-in/docker-compose.yml 2>/dev/null || true
sed -n '1,60p' /opt/apps/dotsai-in/Dockerfile 2>/dev/null || true

echo "=== candidate containers ==="
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}' | grep -iE 'dotsai|dots-ai|website|landing' || true

# nginx:alpine html roots we expect from Dockerfile COPY public/
HTML_PATHS=(
  /usr/share/nginx/html
  /usr/share/nginx/html/dotsai.in
  /usr/share/nginx/html/public
  /app/public
  /app
  /var/www/html
)

DOCKER_TARGETS=()
add_docker() {
  local t="$1"
  local e
  for e in "${DOCKER_TARGETS[@]+"${DOCKER_TARGETS[@]}"}"; do
    [ "$e" = "$t" ] && return 0
  done
  DOCKER_TARGETS+=("$t")
}

find_in_container() {
  local c="$1"
  docker inspect "$c" >/dev/null 2>&1 || return 0
  echo "--- inspect $c aliases/mounts ---"
  docker inspect --format 'image={{.Config.Image}}
names={{json .Name}}
aliases={{range $k,$v := .NetworkSettings.Networks}}{{$k}}:{{json $v.Aliases}} {{end}}
mounts={{range .Mounts}}{{.Source}}->{{.Destination}}; {{end}}' "$c" || true
  local p
  for p in "${HTML_PATHS[@]}"; do
    if docker exec "$c" test -d "$p/blog/$MARKER" 2>/dev/null; then
      echo "FOUND $c:$p"
      add_docker "$c:$p"
    fi
  done
}

# Named containers from compose / older nginx configs
for c in dotsai-in dots-ai-website dots-ai-landing; do
  find_in_container "$c"
done

# Any other running container that already has the textile post
while IFS= read -r c; do
  [ -n "$c" ] || continue
  case "$c" in
    dotsai-in|dots-ai-website|dots-ai-landing) continue ;;
  esac
  for p in /usr/share/nginx/html /usr/share/nginx/html/dotsai.in; do
    if docker exec "$c" test -d "$p/blog/$MARKER" 2>/dev/null; then
      echo "FOUND $c:$p"
      add_docker "$c:$p"
    fi
  done
done < <(docker ps --format '{{.Names}}' | grep -iE 'dotsai|dots-ai|website|landing' || true)

# Resolve what the edge proxy actually talks to
if docker exec nginx true 2>/dev/null; then
  echo "=== edge nginx → upstream ==="
  docker exec nginx sh -c 'wget -qO- --timeout=5 http://dotsai-in/blog/ai-for-textile-industry-surat/ | head -c 120' 2>/dev/null && echo || true
  docker exec nginx sh -c 'wget -qO- --timeout=5 http://dots-ai-website/blog/ai-for-textile-industry-surat/ | head -c 120' 2>/dev/null && echo || true
  docker exec nginx sh -c 'getent hosts dotsai-in dots-ai-website dots-ai-landing 2>/dev/null || nslookup dotsai-in 2>/dev/null || true'
fi

HOST_ROOT=/opt/apps/dotsai-in/public
install_host() {
  local ROOT="$1"
  [ -d "$ROOT" ] || return 0
  echo ">> host $ROOT"
  mkdir -p "$ROOT/blog/private-ai-for-indian-msmes" \
           "$ROOT/blog/tally-automation-ai-msme" \
           "$ROOT/blog/whatsapp-order-automation-msme"
  cp -f "$PAYLOAD/private-ai-for-indian-msmes/index.html" "$ROOT/blog/private-ai-for-indian-msmes/index.html"
  cp -f "$PAYLOAD/tally-automation-ai-msme/index.html" "$ROOT/blog/tally-automation-ai-msme/index.html"
  cp -f "$PAYLOAD/whatsapp-order-automation-msme/index.html" "$ROOT/blog/whatsapp-order-automation-msme/index.html"
  cp -f "$PAYLOAD/index.html" "$ROOT/blog/index.html"
  python3 /tmp/patch-live-blog-seo.py "$ROOT" || echo "WARN: host sitemap patch failed for $ROOT"
}

install_docker() {
  local c="$1" ROOT="$2"
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

  STAGE=$(mktemp -d)
  docker cp "$c:$ROOT/sitemap.xml" "$STAGE/sitemap.xml" 2>/dev/null || true
  docker cp "$c:$ROOT/llms.txt" "$STAGE/llms.txt" 2>/dev/null || true
  if [ -f "$STAGE/sitemap.xml" ]; then
    python3 /tmp/patch-live-blog-seo.py "$STAGE" || echo "WARN: container sitemap patch failed"
    docker cp "$STAGE/sitemap.xml" "$c:$ROOT/sitemap.xml"
    [ -f "$STAGE/llms.txt" ] && docker cp "$STAGE/llms.txt" "$c:$ROOT/llms.txt"
  fi
  rm -rf "$STAGE"
}

echo "=== deploy host source tree ==="
install_host "$HOST_ROOT"

echo "=== deploy docker targets ==="
if [ ${#DOCKER_TARGETS[@]} -eq 0 ]; then
  echo "ERROR: no container with the textile post was found" >&2
  docker ps --format '{{.Names}} {{.Image}}'
  exit 1
fi
for t in "${DOCKER_TARGETS[@]}"; do
  install_docker "${t%%:*}" "${t#*:}"
done

echo "=== reload edge nginx ==="
docker exec nginx nginx -s reload 2>/dev/null && echo "edge nginx reloaded" || echo "WARN: edge nginx reload failed"

echo "=== local origin check ==="
ok=1
for url in \
  "https://dotsai.in/blog/private-ai-for-indian-msmes/" \
  "https://dotsai.in/blog/tally-automation-ai-msme/" \
  "https://dotsai.in/blog/whatsapp-order-automation-msme/" \
  "https://dotsai.in/blog/" \
  "https://dotsai.in/sitemap.xml"; do
  code=$(curl -sk --resolve dotsai.in:443:127.0.0.1 -o /tmp/msme-local-body -w "%{http_code}" "$url" || echo err)
  echo "$code $url"
  head -c 160 /tmp/msme-local-body; echo
  [ "$code" = "200" ] || ok=0
done
if [ "$ok" != "1" ]; then
  echo "ERROR: origin still not serving new posts" >&2
  exit 1
fi
if ! grep -F -q "private-ai-for-indian-msmes" /tmp/msme-local-body && \
   ! curl -sk --resolve dotsai.in:443:127.0.0.1 "https://dotsai.in/blog/" | grep -F -q "private-ai-for-indian-msmes"; then
  echo "ERROR: /blog/ missing new slug" >&2
  exit 1
fi
echo "local origin OK"
