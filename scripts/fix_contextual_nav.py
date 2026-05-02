#!/usr/bin/env python3
"""
Replace .nav-pill links with page-specific contextual links.
Logo always → dotsai.in (already set). CTA always → Book Meet.
Only the pill links in the middle change per page context.
"""
import os, re

ROOT = os.path.join(os.path.dirname(__file__), '..', 'public')

def link(label, href, active=False):
    cls = 'nav-link is-active' if active else 'nav-link'
    return f'<a class="{cls}" href="{href}">{label}</a>'

# ── Contextual nav pill definitions per page ────────────────────────────────
# key = relative path from public/
PAGES = {
    # ── Service pages ─────────────────────────────────────────────────────
    'private-ai/index.html': [
        link('← Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('About', '/about/'),
    ],
    'ai-automation/index.html': [
        link('← Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('About', '/about/'),
    ],
    'geo-ai/index.html': [
        link('← Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('About', '/about/'),
    ],
    'web-ai-experiences/index.html': [
        link('← Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('About', '/about/'),
    ],
    'platform-engineering/index.html': [
        link('← Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('About', '/about/'),
    ],

    # ── Region pages ──────────────────────────────────────────────────────
    'ai-agency-india/index.html': [
        link('← Home', '/'),
        link('Private AI', '/private-ai/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
    'ai-agency-gurugram/index.html': [
        link('← Home', '/'),
        link('Private AI', '/private-ai/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
    'regions/index.html': [
        link('← Home', '/'),
        link('India', '/ai-agency-india/'),
        link('Gurugram', '/ai-agency-gurugram/'),
        link('Pricing', '/pricing/'),
    ],

    # ── Case studies ──────────────────────────────────────────────────────
    'case-studies/index.html': [
        link('← Home', '/'),
        link('NeoNir', '/case-studies/neonir/'),
        link('WORO', '/case-studies/woro/'),
        link('Aamdhanee', '/case-studies/aamdhanee/'),
    ],
    'case-studies/neonir/index.html': [
        link('← Case Studies', '/case-studies/'),
        link('WORO', '/case-studies/woro/'),
        link('Aamdhanee', '/case-studies/aamdhanee/'),
        link('Pricing', '/pricing/'),
    ],
    'case-studies/woro/index.html': [
        link('← Case Studies', '/case-studies/'),
        link('NeoNir', '/case-studies/neonir/'),
        link('Aamdhanee', '/case-studies/aamdhanee/'),
        link('Pricing', '/pricing/'),
    ],
    'case-studies/aamdhanee/index.html': [
        link('← Case Studies', '/case-studies/'),
        link('NeoNir', '/case-studies/neonir/'),
        link('WORO', '/case-studies/woro/'),
        link('Pricing', '/pricing/'),
    ],

    # ── About ─────────────────────────────────────────────────────────────
    'about/index.html': [
        link('← Home', '/'),
        link('Meet Deshani', '/about/meetdeshani/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
    'about/meetdeshani/index.html': [
        link('← About', '/about/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
        link('Services', '/#pillars'),
    ],

    # ── Pricing ───────────────────────────────────────────────────────────
    'pricing/index.html': [
        link('← Home', '/'),
        link('Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('About', '/about/'),
    ],

    # ── Insights ──────────────────────────────────────────────────────────
    'insights/index.html': [
        link('← Home', '/'),
        link('Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],

    # ── Labs ──────────────────────────────────────────────────────────────
    'labs/index.html': [
        link('AI Chat', '/labs/ai-chat/'),
        link('Doc Parser', '/labs/doc-parser/'),
        link('SEO Checker', '/labs/seo-checker/'),
        link('Workflow Viz', '/labs/workflow-viz/'),
    ],
    'labs/ai-chat/index.html': [
        link('← Labs', '/labs/'),
        link('Doc Parser', '/labs/doc-parser/'),
        link('SEO Checker', '/labs/seo-checker/'),
        link('Services', '/#pillars'),
    ],
    'labs/doc-parser/index.html': [
        link('← Labs', '/labs/'),
        link('AI Chat', '/labs/ai-chat/'),
        link('SEO Checker', '/labs/seo-checker/'),
        link('Services', '/#pillars'),
    ],
    'labs/seo-checker/index.html': [
        link('← Labs', '/labs/'),
        link('AI Chat', '/labs/ai-chat/'),
        link('Doc Parser', '/labs/doc-parser/'),
        link('Services', '/#pillars'),
    ],
    'labs/workflow-viz/index.html': [
        link('← Labs', '/labs/'),
        link('AI Chat', '/labs/ai-chat/'),
        link('SEO Checker', '/labs/seo-checker/'),
        link('Services', '/#pillars'),
    ],

    # ── Company ───────────────────────────────────────────────────────────
    'careers/index.html': [
        link('← About', '/about/'),
        link('Team', '/team/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
    'team/index.html': [
        link('← About', '/about/'),
        link('Careers', '/careers/'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
    'sitemap/index.html': [
        link('← Home', '/'),
        link('Services', '/#pillars'),
        link('Case Studies', '/case-studies/'),
        link('Pricing', '/pricing/'),
    ],
}

# Match the nav-pill div and its children
PILL_RE = re.compile(
    r'(<div\s+class="nav-pill"[^>]*>)(.*?)(</div>)',
    re.DOTALL
)

def process(rel_path, links):
    abs_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(abs_path):
        print(f'  SKIP (not found): {rel_path}')
        return

    html = open(abs_path).read()
    inner = '\n    ' + '\n    '.join(links) + '\n  '
    new_html, n = PILL_RE.subn(lambda m: m.group(1) + inner + m.group(3), html, count=1)
    if n:
        open(abs_path, 'w').write(new_html)
        print(f'  updated: {rel_path}')
    else:
        print(f'  no pill found: {rel_path}')

for rel, links in PAGES.items():
    process(rel, links)

print(f'\nDone. {len(PAGES)} pages processed.')
