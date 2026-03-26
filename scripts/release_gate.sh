#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release_gate.sh [domain] [old_domain] [path ...]

Environment:
  OUTDIR                   Override audit output directory
  P1_THRESHOLD             Maximum allowed P1 failures before exit 1 (default: 5)
  PUBLISH_MONITOR_JSON     Copy latest monitor snapshot into public/monitor-data (default: yes)
  ANALYTICS_DATABASE_URL   Optional PostgreSQL URL for DB snapshots
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DOMAIN="${1:-dotsai.in}"
OLD_DOMAIN="${2:-zeroonedotsai.consulting}"
P1_THRESHOLD="${P1_THRESHOLD:-5}"
PUBLISH_MONITOR_JSON="${PUBLISH_MONITOR_JSON:-yes}"

if [[ $# -gt 0 ]]; then
  shift
fi
if [[ $# -gt 0 ]]; then
  shift
fi

timestamp="$(date '+%Y-%m-%d-%H%M%S')"
safe_domain="${DOMAIN//[^A-Za-z0-9.-]/_}"
default_outdir="qa/${timestamp}-${safe_domain}-gate"
OUTDIR="${OUTDIR:-$default_outdir}"
export OUTDIR

./scripts/release_audit.sh "$DOMAIN" "$OLD_DOMAIN" "$@"

monitor_json="${OUTDIR}/monitor.json"
gate_report="${OUTDIR}/gate-report.md"

gate_exit=0
if perl -MJSON::PP -e '
  use strict;
  use warnings;
  use JSON::PP;

  my ($path, $p1_threshold, $report) = @ARGV;
  local $/;
  open my $fh, "<", $path or die "cannot open $path: $!";
  my $data = JSON::PP->new->decode(<$fh>);
  close $fh;

  my $p0_failures = 0;
  my $p1_failures = 0;
  for my $check (@{$data->{checks}}) {
    $p0_failures++ if $check->{severity} eq "P0" && $check->{status} eq "fail";
    $p1_failures++ if $check->{severity} eq "P1" && $check->{status} eq "fail";
  }

  open my $out, ">", $report or die "cannot write $report: $!";
  print {$out} "# Release Gate Report\n\n";
  print {$out} "- Domain: `$data->{domain}`\n";
  print {$out} "- Generated: `$data->{generated_at}`\n";
  print {$out} "- P0 failures: `$p0_failures`\n";
  print {$out} "- P1 failures: `$p1_failures`\n";
  print {$out} "- P1 threshold: `$p1_threshold`\n\n";
  print {$out} "## Checks\n\n";
  for my $check (@{$data->{checks}}) {
    print {$out} "- [$check->{status}] $check->{severity} $check->{name} | expected: `$check->{expected}` | actual: `$check->{actual}`\n";
  }
  close $out;

  print "$p0_failures $p1_failures\n";
  exit(($p0_failures > 0 || $p1_failures > $p1_threshold) ? 1 : 0);
' "$monitor_json" "$P1_THRESHOLD" "$gate_report"; then
  gate_exit=0
else
  gate_exit=$?
fi

if [[ "$PUBLISH_MONITOR_JSON" == "yes" ]]; then
  mkdir -p public/monitor-data
  cp "$monitor_json" public/monitor-data/latest.json
  cp "${OUTDIR}/SUMMARY.md" public/monitor-data/latest-summary.md
  cp "$gate_report" public/monitor-data/latest-gate-report.md
fi

exit "$gate_exit"
