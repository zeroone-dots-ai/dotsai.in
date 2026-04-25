#!/usr/bin/env python3
"""
notify-deploy.py
────────────────
Posts a deploy outcome to Telegram (primary) and Slack (secondary).
Both channels receive both success and failure events.

Driven entirely by env vars so it's identically callable from GitHub Actions
or a local terminal:

  OUTCOME              success | failure | cancelled  (job.status)
  DOMAIN               dotsai.in | test.dotsai.in
  ENVNAME              production | test
  EMOJI                Slack-style emoji string
  GITHUB_SHA           commit hash
  GITHUB_ACTOR         author/triggering user
  GITHUB_SERVER_URL    https://github.com
  GITHUB_REPOSITORY    org/repo
  GITHUB_RUN_ID        numeric run id
  COMMIT_MSG           full commit message (only first line is used)
  SLACK_BOT_TOKEN      xoxb-...
  SLACK_CHANNEL        Cxxxxxxx channel id
  TELEGRAM_BOT_TOKEN   <bot id>:<token>
  TELEGRAM_CHAT_ID     numeric or @username

Exits 0 on success of all attempted notifications, 1 if any fail.
Missing tokens are skipped silently (so the workflow stays green if you've
not set up Telegram yet, etc.).

Local test:
  OUTCOME=success DOMAIN=test.dotsai.in ENVNAME=test EMOJI=:test_tube: \\
  COMMIT_MSG="local test" GITHUB_SHA=$(git rev-parse HEAD) \\
  GITHUB_ACTOR=$(git config user.name) GITHUB_SERVER_URL=https://github.com \\
  GITHUB_REPOSITORY=zeroone-dots-ai/dotsai.in GITHUB_RUN_ID=0 \\
  SLACK_BOT_TOKEN=$(grep SLACK_BOT_TOKEN ~/Desktop/Vault/meet-workstyle-channels/.env | cut -d= -f2) \\
  SLACK_CHANNEL=$(grep SLACK_TEST_CHANNEL_ID ~/Desktop/Vault/meet-workstyle-channels/.env | cut -d= -f2) \\
  python3 scripts/notify-deploy.py
"""
import json
import os
import sys
import urllib.request
import urllib.parse
import urllib.error


def env(key: str, default: str = "") -> str:
    return os.environ.get(key, default) or default


def post_slack(text: str) -> tuple[bool, str]:
    token = env("SLACK_BOT_TOKEN")
    channel = env("SLACK_CHANNEL")
    if not token or not channel:
        return True, "skipped (no token/channel)"

    payload = json.dumps({"channel": channel, "text": text, "mrkdwn": True}).encode()
    req = urllib.request.Request(
        "https://slack.com/api/chat.postMessage",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json; charset=utf-8",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            body = json.loads(r.read())
            if body.get("ok"):
                return True, f"posted to {channel}"
            return False, f"slack api error: {body.get('error')}"
    except urllib.error.URLError as e:
        return False, f"slack network error: {e}"


def post_telegram(text: str) -> tuple[bool, str]:
    token = env("TELEGRAM_BOT_TOKEN")
    chat = env("TELEGRAM_CHAT_ID")
    if not token or not chat:
        return True, "skipped (no token/chat)"

    data = urllib.parse.urlencode({
        "chat_id": chat,
        "text": text,
        "parse_mode": "Markdown",
        "disable_web_page_preview": "true",
    }).encode()

    try:
        with urllib.request.urlopen(
            f"https://api.telegram.org/bot{token}/sendMessage",
            data=data, timeout=10,
        ) as r:
            body = json.loads(r.read())
            if body.get("ok"):
                return True, f"posted to {chat}"
            return False, f"telegram api error: {body.get('description')}"
    except urllib.error.URLError as e:
        return False, f"telegram network error: {e}"


def build_messages():
    outcome = env("OUTCOME", "unknown").lower()
    domain  = env("DOMAIN", "?")
    envname = env("ENVNAME", "?")
    emoji   = env("EMOJI", ":package:")
    sha     = env("GITHUB_SHA", "")[:7] or "unknown"
    actor   = env("GITHUB_ACTOR", "unknown")
    msg     = env("COMMIT_MSG", "").splitlines()[0] if env("COMMIT_MSG") else "(no commit message)"
    run_url = (
        f"{env('GITHUB_SERVER_URL', 'https://github.com')}"
        f"/{env('GITHUB_REPOSITORY', '')}"
        f"/actions/runs/{env('GITHUB_RUN_ID', '')}"
    )

    if outcome == "success":
        slack_text = (
            f"{emoji} *{domain}* deployed ({envname})\n"
            f"`{sha}` {msg}\n"
            f"by _{actor}_ · <{run_url}|run>"
        )
        tg_text = (
            f"✅ *{domain}* deployed _({envname})_\n"
            f"`{sha}` {msg}\n"
            f"by _{actor}_\n"
            f"[view run]({run_url})"
        )
        return slack_text, tg_text

    # failure or cancelled — alert both, with louder framing
    label = "FAILED" if outcome == "failure" else outcome.upper()
    slack_text = (
        f":x: *{domain}* deploy {label} ({envname})\n"
        f"`{sha}` {msg}\n"
        f"by _{actor}_ · <{run_url}|investigate>"
    )
    tg_text = (
        f"🔴 *{domain}* deploy {label} _({envname})_\n"
        f"`{sha}` {msg}\n"
        f"by _{actor}_\n"
        f"[investigate]({run_url})"
    )
    return slack_text, tg_text


def main():
    slack_text, tg_text = build_messages()
    rc = 0

    ok, info = post_slack(slack_text)
    print(f"slack:    {'ok' if ok else 'FAIL'} — {info}")
    if not ok: rc = 1

    if tg_text is not None:
        ok, info = post_telegram(tg_text)
        print(f"telegram: {'ok' if ok else 'FAIL'} — {info}")
        if not ok: rc = 1
    else:
        print("telegram: skipped (success path)")

    sys.exit(rc)


if __name__ == "__main__":
    main()
