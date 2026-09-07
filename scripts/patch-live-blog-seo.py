#!/usr/bin/env python3
"""Patch live sitemap.xml + llms.txt with the three MSME blog URLs. Idempotent."""
from pathlib import Path

ROOT = Path("/opt/services/nginx/html/dotsai.in")
URLS = [
    "https://dotsai.in/blog/private-ai-for-indian-msmes/",
    "https://dotsai.in/blog/tally-automation-ai-msme/",
    "https://dotsai.in/blog/whatsapp-order-automation-msme/",
]
LASTMOD = "2026-09-07"

sitemap = ROOT / "sitemap.xml"
text = sitemap.read_text(encoding="utf-8")
text = text.replace(
    "<url><loc>https://dotsai.in/blog/</loc><lastmod>2026-08-16</lastmod></url>",
    f"<url><loc>https://dotsai.in/blog/</loc><lastmod>{LASTMOD}</lastmod></url>",
)
added = 0
for url in URLS:
    if url in text:
        continue
    entry = f"  <url><loc>{url}</loc><lastmod>{LASTMOD}</lastmod></url>\n"
    if "</urlset>" not in text:
        raise SystemExit("sitemap.xml missing </urlset>")
    text = text.replace("</urlset>", entry + "</urlset>")
    added += 1
sitemap.write_text(text, encoding="utf-8")
print(f"sitemap.xml: added {added} url(s)")

llms = ROOT / "llms.txt"
lt = llms.read_text(encoding="utf-8")
if "private-ai-for-indian-msmes" in lt:
    print("llms.txt: already lists new posts")
else:
    extra = (
        "- [Private AI for Indian MSMEs](https://dotsai.in/blog/private-ai-for-indian-msmes/): "
        "own it, don't rent it — on-prem models for Surat/Gujarat MSMEs; NeoNir reports 2–3 hours → ~10 minutes, ₹0 cloud bills\n"
        "- [Tally automation with AI](https://dotsai.in/blog/tally-automation-ai-msme/): "
        "Munshi reads PDF/photo bills, matches challans, books Tally drafts for accountant approval\n"
        "- [WhatsApp order automation](https://dotsai.in/blog/whatsapp-order-automation-msme/): "
        "texts, voice notes and photos of chits → a structured order register, confirmation on the same thread\n"
    )
    old = (
        "- [Blog — AI for MSMEs](https://dotsai.in/blog/): practical, proof-backed posts; "
        "first post: AI for the textile industry in Surat (5 workflows that pay)"
    )
    if old in lt:
        lt = lt.replace(
            old,
            old.replace("first post:", "posts include:")
            + "\n"
            + extra.rstrip("\n"),
            1,
        )
    else:
        lt = lt.rstrip() + "\n\n## MSME blog posts (Sep 2026)\n" + extra
    llms.write_text(lt, encoding="utf-8")
    print("llms.txt: appended three posts")
