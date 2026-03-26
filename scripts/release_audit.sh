#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release_audit.sh [domain] [old_domain] [path ...]

Examples:
  ./scripts/release_audit.sh
  ./scripts/release_audit.sh dotsai.in zeroonedotsai.consulting
  ./scripts/release_audit.sh dotsai.in zeroonedotsai.consulting /ai-agency-india /private-ai /geo-ai

Environment:
  OUTDIR                  Override output directory
  ANALYTICS_DATABASE_URL  Optional PostgreSQL URL for DB snapshots
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DOMAIN="${1:-dotsai.in}"
OLD_DOMAIN="${2:-zeroonedotsai.consulting}"
shift $(( $# > 0 ? 1 : 0 )) || true
shift $(( $# > 0 ? 1 : 0 )) || true

DEFAULT_PATHS=(
  "/"
  "/ai-agency-india"
  "/private-ai"
  "/ai-automation"
  "/geo-ai"
  "/web-ai-experiences"
  "/platform-engineering"
  "/case-studies"
  "/insights"
)
if [[ "$#" -gt 0 ]]; then
  PATHS=("$@")
else
  PATHS=("${DEFAULT_PATHS[@]}")
fi

timestamp="$(date '+%Y-%m-%d-%H%M%S')"
safe_domain="${DOMAIN//[^A-Za-z0-9.-]/_}"
outdir="${OUTDIR:-qa/${timestamp}-${safe_domain}}"
mkdir -p "$outdir"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

for cmd in curl grep sed awk dig openssl; do
  require_cmd "$cmd"
done

if command -v psql >/dev/null 2>&1 && [[ -n "${ANALYTICS_DATABASE_URL:-}" ]]; then
  have_db="yes"
else
  have_db="no"
fi

fetch_headers() {
  local url="$1"
  local outfile="$2"
  curl -sSIL --max-redirs 5 "$url" >"$outfile" || true
}

fetch_body() {
  local url="$1"
  local outfile="$2"
  curl -sSL --max-redirs 5 "$url" >"$outfile" || true
}

last_status() {
  local file="$1"
  awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}' "$file"
}

header_value() {
  local file="$1"
  local key="$2"
  awk -F': ' -v wanted="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')" '
    {
      current=tolower($1)
      gsub(/\r/, "", $2)
      if (current == wanted) {
        value=$2
      }
    }
    END {print value}
  ' "$file"
}

extract_canonical() {
  local file="$1"
  tr '\n' ' ' <"$file" \
    | grep -ioE '<link[^>]+rel=["'"'"']canonical["'"'"'][^>]+href=["'"'"'][^"'"'"']+' \
    | sed -E 's/.*href=["'"'"']([^"'"'"']+).*/\1/' \
    | head -n 1 || true
}

extract_title() {
  local file="$1"
  perl -MEncode=decode -0ne '
    $_ = decode("UTF-8", $_, 1);
    if (m{<title>(.*?)</title>}is) {
      $t = $1;
      $t =~ s/\s+/ /g;
      $t =~ s/^\s+|\s+$//g;
      print $t;
    }
  ' "$file" 2>/dev/null || true
}

count_non_primary_loc_urls() {
  local file="$1"
  local host="$2"
  perl -e '
    use strict;
    use warnings;

    my ($path, $primary_host) = @ARGV;
    local $/;
    open my $fh, "<", $path or do {
      print "0";
      exit 0;
    };
    my $xml = <$fh>;
    close $fh;

    my $count = 0;
    while ($xml =~ m{<loc>\s*(https?://[^<]+)\s*</loc>}g) {
      my $url = $1;
      my $host = $url;
      $host =~ s{^https?://}{};
      $host =~ s{/.*$}{};
      $count++ if $host ne $primary_host;
    }
    print $count;
  ' "$file" "$host"
}

record_path_artifacts() {
  local path="$1"
  local label="$2"
  local url="https://${DOMAIN}${path}"
  local headers_file="${outdir}/${label}.headers.txt"
  local body_file="${outdir}/${label}.body.html"

  fetch_headers "$url" "$headers_file"
  fetch_body "$url" "$body_file"

  {
    echo "URL: $url"
    echo "Status: $(last_status "$headers_file")"
    echo "Canonical: $(extract_canonical "$body_file")"
    echo "X-Robots-Tag: $(header_value "$headers_file" "x-robots-tag")"
    echo "Content-Type: $(header_value "$headers_file" "content-type")"
    echo "Cache-Control: $(header_value "$headers_file" "cache-control")"
    echo "Title: $(extract_title "$body_file")"
  } > "${outdir}/${label}.summary.txt"
}

summary_file="${outdir}/SUMMARY.md"
touch "$summary_file"

echo "# Release Audit Summary" >"$summary_file"
echo >>"$summary_file"
echo "- Domain: \`${DOMAIN}\`" >>"$summary_file"
echo "- Old domain: \`${OLD_DOMAIN}\`" >>"$summary_file"
echo "- Generated: \`${timestamp}\`" >>"$summary_file"
echo "- Output: \`${outdir}\`" >>"$summary_file"
echo >>"$summary_file"

{
  echo "## DNS"
  echo
  echo '```text'
  echo "A/AAAA for ${DOMAIN}:"
  dig +short "$DOMAIN"
  echo
  echo "A/AAAA for www.${DOMAIN}:"
  dig +short "www.${DOMAIN}" || true
  echo '```'
  echo
} > "${outdir}/01-dns.txt"

{
  echo "## TLS"
  echo
  echo '```text'
  openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates || true
  echo '```'
  echo
} > "${outdir}/02-tls.txt"

fetch_headers "https://${DOMAIN}/" "${outdir}/03-home.headers.txt"
fetch_headers "https://${DOMAIN}/this-should-not-exist" "${outdir}/04-missing.headers.txt"
fetch_headers "https://${OLD_DOMAIN}/" "${outdir}/05-old-domain.headers.txt"
fetch_headers "https://www.${DOMAIN}/" "${outdir}/06-www.headers.txt"
fetch_headers "https://${DOMAIN}/" "${outdir}/07-googlebot.headers.txt"
curl -sSIL --max-redirs 5 -A "Googlebot/2.1 (+http://www.google.com/bot.html)" "https://${DOMAIN}/" > "${outdir}/07-googlebot.headers.txt" || true
curl -sSIL --max-redirs 5 -A "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)" "https://${DOMAIN}/" > "${outdir}/08-bingbot.headers.txt" || true
curl -sSIL --max-redirs 5 -A "Mozilla/5.0 (compatible; OAI-SearchBot/1.0; +https://openai.com/searchbot)" "https://${DOMAIN}/" > "${outdir}/09-oai-searchbot.headers.txt" || true
fetch_body "https://${DOMAIN}/robots.txt" "${outdir}/10-robots.txt"
fetch_body "https://${DOMAIN}/sitemap.xml" "${outdir}/11-sitemap.xml"
fetch_headers "https://${DOMAIN}/og-image.png" "${outdir}/13-og-image.headers.txt"
fetch_headers "https://${DOMAIN}/favicon.svg" "${outdir}/14-favicon.headers.txt"

record_path_artifacts "/" "12-homepage"
for path in "${PATHS[@]}"; do
  label="$(printf '%s' "$path" | sed 's#^/##; s#[^A-Za-z0-9._-]#-#g')"
  if [[ -z "$label" ]]; then
    continue
  fi
  record_path_artifacts "$path" "path-${label}"
done

{
  echo "## High-level checks"
  echo

  home_status="$(last_status "${outdir}/03-home.headers.txt")"
  missing_status="$(last_status "${outdir}/04-missing.headers.txt")"
  old_status="$(last_status "${outdir}/05-old-domain.headers.txt")"
  www_status="$(last_status "${outdir}/06-www.headers.txt")"
  home_xrobots="$(header_value "${outdir}/03-home.headers.txt" "x-robots-tag")"
  home_xrobots_lc="$(printf '%s' "${home_xrobots:-}" | tr '[:upper:]' '[:lower:]')"
  home_canonical="$(extract_canonical "${outdir}/12-homepage.body.html")"
  robots_sitemap="$(grep -i '^sitemap:' "${outdir}/10-robots.txt" | head -n 1 | sed 's/\r//' || true)"
  foreign_sitemap_count="$(count_non_primary_loc_urls "${outdir}/11-sitemap.xml" "${DOMAIN}")"
  og_image_status="$(last_status "${outdir}/13-og-image.headers.txt")"
  og_image_type="$(header_value "${outdir}/13-og-image.headers.txt" "content-type")"
  favicon_status="$(last_status "${outdir}/14-favicon.headers.txt")"
  favicon_type="$(header_value "${outdir}/14-favicon.headers.txt" "content-type")"

  echo "- Homepage status: \`${home_status:-unknown}\`"
  echo "- Missing URL status: \`${missing_status:-unknown}\`"
  echo "- Old domain terminal status: \`${old_status:-unknown}\`"
  echo "- www terminal status: \`${www_status:-unknown}\`"
  echo "- Homepage X-Robots-Tag: \`${home_xrobots:-none}\`"
  echo "- Homepage canonical: \`${home_canonical:-missing}\`"
  echo "- robots.txt sitemap line: \`${robots_sitemap:-missing}\`"
  echo "- Foreign sitemap URL count: \`${foreign_sitemap_count:-0}\`"
  echo "- OG image status/content-type: \`${og_image_status:-unknown}\` / \`${og_image_type:-unknown}\`"
  echo "- Favicon status/content-type: \`${favicon_status:-unknown}\` / \`${favicon_type:-unknown}\`"
  echo

  echo "## Release signals"
  echo

  if [[ "${home_status:-}" == "200" ]]; then
    echo "- PASS: homepage returns 200"
  else
    echo "- FAIL: homepage does not return 200"
  fi

  if [[ "${missing_status:-}" == "404" || "${missing_status:-}" == "410" ]]; then
    echo "- PASS: missing URL returns a real error status"
  else
    echo "- FAIL: missing URL does not return 404/410"
  fi

  if [[ "${home_xrobots_lc:-}" == *"noindex"* ]]; then
    echo "- FAIL: production homepage is sending noindex"
  else
    echo "- PASS: production homepage is not sending noindex"
  fi

  if [[ "${home_canonical:-}" == "https://${DOMAIN}/" || "${home_canonical:-}" == "https://${DOMAIN}" ]]; then
    echo "- PASS: homepage canonical points to ${DOMAIN}"
  else
    echo "- FAIL: homepage canonical is missing or points elsewhere"
  fi

  if [[ "${robots_sitemap:-}" == *"${DOMAIN}"* ]]; then
    echo "- PASS: robots.txt points to a sitemap on ${DOMAIN}"
  else
    echo "- FAIL: robots.txt sitemap line is missing or points elsewhere"
  fi

  if [[ "${foreign_sitemap_count:-0}" == "0" ]]; then
    echo "- PASS: sitemap does not obviously contain foreign-host URLs"
  else
    echo "- FAIL: sitemap includes URLs outside ${DOMAIN}"
  fi

  if [[ "${og_image_status:-}" == "200" && "${og_image_type:-}" == image/* ]]; then
    echo "- PASS: OG image resolves as an image asset"
  else
    echo "- FAIL: OG image is missing or not served as an image asset"
  fi

  if [[ "${favicon_status:-}" == "200" && "${favicon_type:-}" == image/* ]]; then
    echo "- PASS: favicon resolves as an image asset"
  else
    echo "- FAIL: favicon is missing or not served as an image asset"
  fi
  echo
} >>"$summary_file"

if [[ "$have_db" == "yes" ]]; then
  {
    echo "## Database snapshots"
    echo
    echo '```sql'
    psql "$ANALYTICS_DATABASE_URL" -c "select session_id, started_at, entry_path, landing_touch_id from analytics.sessions order by started_at desc limit 10;"
    psql "$ANALYTICS_DATABASE_URL" -c "select source, medium, campaign, occurred_at from analytics.attribution_touches order by occurred_at desc limit 10;"
    psql "$ANALYTICS_DATABASE_URL" -c "select event_name, occurred_at, path from analytics.events order by occurred_at desc limit 20;"
    echo '```'
  } > "${outdir}/20-db-snapshots.md" || true

  echo "- INFO: database snapshots were collected" >>"$summary_file"
else
  echo "- INFO: database snapshots skipped because ANALYTICS_DATABASE_URL was not set or psql was unavailable" >>"$summary_file"
fi

cat <<EOF >>"$summary_file"

## Manual follow-up

- run the full checklist in \`research/08-launch-readiness-checklist.md\`
- run the full QA matrix in \`research/09-qa-validation-matrix.md\`
- capture screenshots, Search Console evidence, and form traces into this release folder
EOF

perl -MJSON::PP -e '
  use strict;
  use warnings;
  use JSON::PP;

  my ($domain, $old_domain, $timestamp, $outdir) = @ARGV;

  sub slurp {
    my ($path) = @_;
    local $/;
    open my $fh, "<", $path or return "";
    my $content = <$fh>;
    close $fh;
    return defined $content ? $content : "";
  }

  sub last_status_from_headers {
    my ($text) = @_;
    my $status = "";
    while ($text =~ /^HTTP\/\S+\s+(\d+)/mg) {
      $status = $1;
    }
    return $status;
  }

  sub header_value {
    my ($text, $wanted) = @_;
    for my $line (split /\n/, $text) {
      my ($key, $value) = split /:\s+/, $line, 2;
      next unless defined $value;
      if (lc($key) eq lc($wanted)) {
        $value =~ s/\r//g;
        return $value;
      }
    }
    return "";
  }

  sub parse_summary_file {
    my ($path) = @_;
    my %row = ( file => $path );
    for my $line (split /\n/, slurp($path)) {
      my ($key, $value) = split /:\s+/, $line, 2;
      next unless defined $value;
      $key =~ s/\s+/_/g;
      $key = lc($key);
      $row{$key} = $value;
    }
    if ($row{url} && $row{url} =~ m{https?://[^/]+(/.*)$}) {
      $row{path} = $1;
    } elsif ($row{url} && $row{url} =~ m{https?://[^/]+$}) {
      $row{path} = "/";
    }
    return \%row;
  }

  my $home_headers = slurp("$outdir/03-home.headers.txt");
  my $missing_headers = slurp("$outdir/04-missing.headers.txt");
  my $old_headers = slurp("$outdir/05-old-domain.headers.txt");
  my $www_headers = slurp("$outdir/06-www.headers.txt");
  my $robots_txt = slurp("$outdir/10-robots.txt");
  my $sitemap_xml = slurp("$outdir/11-sitemap.xml");
  my $home_summary = parse_summary_file("$outdir/12-homepage.summary.txt");
  my $og_headers = slurp("$outdir/13-og-image.headers.txt");
  my $favicon_headers = slurp("$outdir/14-favicon.headers.txt");

  my ($robots_sitemap) = $robots_txt =~ /^Sitemap:\s*(.+)$/mi;
  $robots_sitemap ||= "";

  my @sitemap_urls = ($sitemap_xml =~ m{<loc>\s*(https?://[^<\s"]+)\s*</loc>}g);
  my $foreign_count = 0;
  for my $url (@sitemap_urls) {
    my $host = $url;
    $host =~ s{^https?://}{};
    $host =~ s{/.*$}{};
    $foreign_count++ if $host ne $domain;
  }

  my @checks = (
    {
      id => "home_status",
      name => "Homepage returns 200",
      severity => "P0",
      expected => "200",
      actual => scalar(last_status_from_headers($home_headers)),
    },
    {
      id => "missing_status",
      name => "Missing URL returns 404 or 410",
      severity => "P0",
      expected => "404 or 410",
      actual => scalar(last_status_from_headers($missing_headers)),
    },
    {
      id => "noindex_header",
      name => "Homepage is not noindex",
      severity => "P0",
      expected => "no noindex header",
      actual => scalar(header_value($home_headers, "x-robots-tag")) || "none",
    },
    {
      id => "home_canonical",
      name => "Homepage canonical points to primary domain",
      severity => "P0",
      expected => "https://$domain/",
      actual => ($home_summary->{canonical} || ""),
    },
    {
      id => "robots_sitemap",
      name => "robots.txt points to primary sitemap",
      severity => "P0",
      expected => "sitemap on $domain",
      actual => $robots_sitemap,
    },
    {
      id => "sitemap_foreign_urls",
      name => "Sitemap contains only primary-domain URLs",
      severity => "P0",
      expected => "0 foreign URLs",
      actual => "$foreign_count foreign URLs",
    },
    {
      id => "og_image_asset",
      name => "OG image resolves as an image asset",
      severity => "P1",
      expected => "200 + image content-type",
      actual => scalar(last_status_from_headers($og_headers)) . " / " . (scalar(header_value($og_headers, "content-type")) || "missing"),
    },
    {
      id => "favicon_asset",
      name => "Favicon resolves as an image asset",
      severity => "P1",
      expected => "200 + image content-type",
      actual => scalar(last_status_from_headers($favicon_headers)) . " / " . (scalar(header_value($favicon_headers, "content-type")) || "missing"),
    },
    {
      id => "old_domain_redirect",
      name => "Legacy domain resolves cleanly",
      severity => "P1",
      expected => "final public target on $domain",
      actual => scalar(last_status_from_headers($old_headers)),
    },
    {
      id => "www_domain_redirect",
      name => "www host resolves cleanly",
      severity => "P1",
      expected => "final public target on $domain",
      actual => scalar(last_status_from_headers($www_headers)),
    },
  );

  for my $check (@checks) {
    my $status = "warn";
    if ($check->{id} eq "home_status") {
      $status = $check->{actual} eq "200" ? "pass" : "fail";
    } elsif ($check->{id} eq "missing_status") {
      $status = ($check->{actual} eq "404" || $check->{actual} eq "410") ? "pass" : "fail";
    } elsif ($check->{id} eq "noindex_header") {
      $status = lc($check->{actual}) =~ /noindex/ ? "fail" : "pass";
    } elsif ($check->{id} eq "home_canonical") {
      $status = ($check->{actual} eq "https://$domain/" || $check->{actual} eq "https://$domain") ? "pass" : "fail";
    } elsif ($check->{id} eq "robots_sitemap") {
      $status = $check->{actual} =~ /\Q$domain\E/ ? "pass" : "fail";
    } elsif ($check->{id} eq "sitemap_foreign_urls") {
      $status = $foreign_count == 0 ? "pass" : "fail";
    } elsif ($check->{id} eq "og_image_asset" || $check->{id} eq "favicon_asset") {
      $status = $check->{actual} =~ /^200 \/ image\// ? "pass" : "fail";
    } else {
      $status = $check->{actual} eq "200" || $check->{actual} eq "301" || $check->{actual} eq "308" ? "pass" : "warn";
    }
    $check->{status} = $status;
  }

  my @pages;
  for my $file (sort glob("$outdir/*summary.txt")) {
    push @pages, parse_summary_file($file);
  }

  my $p0_failures = scalar grep { $_->{severity} eq "P0" && $_->{status} eq "fail" } @checks;
  my $p1_failures = scalar grep { $_->{severity} eq "P1" && $_->{status} eq "fail" } @checks;

  my %payload = (
    domain => $domain,
    old_domain => $old_domain,
    generated_at => $timestamp,
    output_dir => $outdir,
    counts => {
      checks => scalar(@checks),
      pages => scalar(@pages),
      p0_failures => $p0_failures,
      p1_failures => $p1_failures,
      sitemap_urls => scalar(@sitemap_urls),
      sitemap_foreign_urls => $foreign_count,
    },
    checks => \@checks,
    pages => \@pages,
    artifacts => [
      "SUMMARY.md",
      "01-dns.txt",
      "02-tls.txt",
      "10-robots.txt",
      "11-sitemap.xml",
    ],
  );

  print JSON::PP->new->ascii->pretty->canonical->encode(\%payload);
' "$DOMAIN" "$OLD_DOMAIN" "$timestamp" "$outdir" > "${outdir}/monitor.json"

echo "audit written to ${outdir}"
