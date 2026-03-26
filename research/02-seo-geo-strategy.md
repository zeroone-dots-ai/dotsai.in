# SEO + GEO Strategy

Strategy date: March 26, 2026
Target market: India first, with optional global credibility
Primary goal: win more commercial-intent work for `AI Agency`, `AI Consulting`, `Private AI`, and related terms

## Reality check
- You can improve eligibility to rank highly and to be cited by ChatGPT/Gemini.
- You cannot guarantee that Google, ChatGPT, Gemini, or any other assistant will declare you the best AI agency.
- The practical goal is to become one of the easiest Indian AI agencies to crawl, understand, trust, cite, and contact.

## The winning model
- Use `dotsai.in` as the main brand and canonical domain if that is the public brand you want to own.
- Build one premium homepage that acts as the narrative and conversion hub.
- Support it with focused subpages that target specific demand and proof topics.
- Build off-site authority and local entity strength so assistants and search systems repeatedly see the same story about your business.

## Non-negotiables before relaunch

### Domain and indexing
1. Pick one primary domain.
2. 301 redirect the secondary domain to the primary domain.
3. Update canonicals, hreflang, OG URLs, JSON-LD URLs, and sitemap URLs to the primary domain.
4. Submit the correct sitemap in Search Console.
5. Verify both the domain property and the exact URL-prefix properties you care about.

### Route handling
1. Return real `404` responses for missing pages.
2. Remove route duplication such as `/services` vs `/solutions`.
3. Make sure internal links only point to canonical URLs.
4. Keep all important pages reachable from normal HTML links.

### JavaScript / rendering
1. Server-render or pre-render all core marketing pages where possible.
2. Keep unique titles, descriptions, and canonicals in the original HTML.
3. Avoid relying on fragments for routing.
4. Use meaningful status codes for errors and moved pages.

## Recommended information architecture

### Keep this as the brand homepage
- `/`
- Purpose: brand, manifesto, conversion, authority, internal linking hub
- Target query family:
  - AI agency India
  - AI consulting India
  - private AI agency
  - founder-led AI agency

### Create subfolder service pages
- `/services/private-ai`
- `/services/ai-automation`
- `/services/ai-agents`
- `/services/ai-platforms`
- `/services/geo`
- `/services/ai-web-experiences`

### Create proof pages
- `/case-studies/`
- `/case-studies/private-ai-for-manufacturing`
- `/case-studies/ai-automation-for-logistics`
- `/case-studies/ai-agent-for-d2c-operations`

### Create authority pages
- `/about`
- `/about/meet-deshani`
- `/process`
- `/security`
- `/faq`

### Create content cluster pages
- `/insights/ai-agency-india`
- `/insights/private-ai-india`
- `/insights/on-prem-ai-vs-cloud`
- `/insights/ai-agents-for-business`
- `/insights/ai-consulting-cost-india`

### Local pages only if real
- `/locations/ahmedabad`
- `/locations/gujarat`
- `/locations/india`

Create these only if you can support them with real local relevance, specific proof, and a consistent business profile.

## Do not split into subdomains yet

### Recommended now
- Use subfolders.
- Keep all authority, links, and entity signals concentrated on one host.

### Why
- Google’s site-name documentation treats domain and subdomain roots as separate sites for site-name purposes.
- That means subdomains introduce separate identity overhead.
- Early subdomain splitting also creates duplicate SEO work:
  - separate homepages
  - separate internal link ecosystems
  - weaker shared authority
  - more complex measurement

### When subdomains do make sense later
- A real software product
- A client portal
- A tool/app with its own lifecycle
- A community/product area that is no longer just a service page

## How to rank for `AI Agency` work in India

### 1. Make the homepage commercially explicit
- The homepage should not only say what you believe.
- It must also say what you sell and who hires you.

Recommended homepage framing:
- Founder-led AI agency in India
- Private AI systems, AI agents, and applied automation
- Built for enterprises, operators, and high-value founder-led businesses

### 2. Build one page per intent cluster
- One URL cannot rank strongly for every service, industry, and city intent.
- Each service page needs:
  - one clear H1
  - one clear commercial intent
  - proof
  - CTA
  - internal links to related pages

### 3. Publish public proof
- Named or anonymized case studies with concrete metrics
- Before/after operations stories
- Sector-specific implementation notes
- Founder commentary on tradeoffs and security

Assistants cite what they can see and repeat. Vague capability claims are weaker than public proof.

### 4. Tighten entity consistency
- Same business name across:
  - site
  - Google Business Profile
  - LinkedIn
  - YouTube
  - GitHub
  - founder profiles
  - directory and press mentions
- Use the same primary domain, brand spelling, description, and contact details everywhere practical.

### 5. Improve local relevance
- Create and verify a Google Business Profile.
- Choose the most accurate primary category.
- Keep hours, phone, address/service area, and website current.
- Ask for real reviews from successful clients.
- Add business photos and founder/team photos.

Google explicitly says local results are mainly based on relevance, distance, and prominence.

## GEO and assistant-surface strategy

## ChatGPT
- OpenAI says any public website can appear in ChatGPT search.
- To help inclusion in summaries and snippets, do not block `OAI-SearchBot`.
- OpenAI does not provide a way to guarantee top placement.
- Track ChatGPT referrals through `utm_source=chatgpt.com`.

## Gemini / Google
- `Google-Extended` controls Gemini training and grounding permissions.
- Google explicitly says `Google-Extended` is not a Google Search ranking signal.
- Gemini visibility still depends heavily on public web understanding, search index strength, entity trust, and helpful source material.

## NotebookLM
- NotebookLM is not a discovery surface in the normal SEO sense.
- Google documents `Google-NotebookLM` as a user-triggered fetcher for URLs users explicitly add as sources.
- That means you do not “rank in NotebookLM.” You become useful enough that people choose your URLs as sources.

## What improves assistant citations in practice
- Crawlable public pages
- Consistent entity signals
- High-specificity case studies
- Clear titles and summaries
- Real-world examples with dates and sectors
- Public mentions from other trusted sites
- Clean, accessible page structure

## Structured data plan
- Home page:
  - `WebSite`
  - `Organization`
  - `Person` for Meet Deshani
- Location/business page:
  - `ProfessionalService` or `LocalBusiness` if it matches the real-world business setup
- Service pages:
  - `Service`
- Case studies:
  - `Article` or `WebPage`
- All subpages:
  - `BreadcrumbList`

## On-page rules
- Unique title for every indexable page
- One primary H1 per page
- Meta description written for click-through, not keyword stuffing
- Clear link text
- Descriptive URLs
- Strong intro paragraph above the fold
- Visible proof near the top of important commercial pages
- Remove reliance on the meta keywords tag

## Content clusters to build

### Head / money pages
- AI Agency in India
- AI Consulting in India
- Private AI Development in India
- AI Automation Agency
- Enterprise AI Agency India

### Problem/solution pages
- On-prem AI vs cloud AI
- AI agents for operations
- Private AI for manufacturers
- AI for logistics teams
- AI for D2C operators
- AI systems that work without internet

### Founder authority pages
- How we scope AI projects
- How we price by outcome
- When not to use AI agents
- Private AI security checklist for Indian businesses

## First 90 days

### Phase 1: technical cleanup
- canonical domain fix
- redirect fix
- soft-404 fix
- sitemap fix
- route alignment
- Search Console setup

### Phase 2: commercial architecture
- new homepage
- service page set
- case study framework
- founder page

### Phase 3: authority
- Google Business Profile
- review collection
- PR / podcast / community mentions
- weekly insight publishing
- ongoing internal linking

## Core recommendation
- Treat the homepage as the premium flagship.
- Treat service pages and case studies as the ranking engine.
- Treat entity consistency and proof as the GEO engine.
