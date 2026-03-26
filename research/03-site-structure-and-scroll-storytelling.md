# Site Structure And Scroll Storytelling

## Short answer
The best architecture is not a pure one-page site and not an early subdomain split.

The best architecture is:
- one premium single-page homepage at `/`
- service pages in subfolders
- case studies in subfolders
- insights in subfolders

This gives you the design freedom you want and the search depth you need.

## Why a pure one-page site is a bad fit for the goal
- One URL cannot carry every title, H1, proof story, service intent, and local intent well.
- Ranking for `AI Agency`, `Private AI`, `AI Automation`, and local terms needs separate indexable entry points.
- Internal linking becomes shallow.
- Richer structured data opportunities become limited.
- The page becomes harder to maintain as the business evolves.

## Why early service subdomains are the wrong move
- Google supports site names at the domain or subdomain root, not the subdirectory level.
- That means subdomains behave more like separate sites than simple sections.
- For a young or growing service brand, that usually means diluted authority and more SEO work.

## Recommended structure

### Homepage
- `/`
- Purpose: premium brand narrative + CTA + routing to money pages

### Services
- `/services/private-ai`
- `/services/ai-automation`
- `/services/ai-agents`
- `/services/geo`
- `/services/ai-platforms`
- `/services/web-ai`

### Proof
- `/case-studies/...`

### Insights
- `/insights/...`

### Local
- `/locations/ahmedabad`
- `/locations/india`

Only keep local pages that can be defended with real business relevance.

## Homepage model: compartment scrolling

### Principle
The homepage should feel like one elegant narrative made of chapters.

Each chapter should:
- own the viewport
- have one dominant idea
- use one motion system
- hand off cleanly to the next chapter

### Recommended chapter sequence

#### Chapter 1: Manifesto Hero
- Keep the core line: `Own Your AI. Don't Rent It.`
- Add a sharper agency framing line above or below it.
- Use a restrained glow or moving light field, not a busy particle system.

#### Chapter 2: Why Private AI Matters
- Pinned chapter with three ideas unfolding on scroll:
  - privacy
  - ownership
  - business leverage
- This is where the scroll should educate, not just decorate.

#### Chapter 3: What DotsAI Builds
- Pinned service rail or stacked panels.
- Each service gets one sentence, one proof cue, one CTA path.
- No bento boxes.

#### Chapter 4: Proof / Results
- Numbers, short case-study summaries, sector logos if available.
- Scroll can reveal outcomes progressively.
- This chapter must feel concrete, not inspirational.

#### Chapter 5: Founder-Led Agency
- Explain why a solo-led practice is a strength:
  - direct access
  - speed
  - accountability
  - no strategy-to-junior handoff

#### Chapter 6: CTA / Contact
- High-trust closing section.
- One primary CTA.
- One secondary CTA.
- Tight FAQ or reassurance band below.

## Motion system rules

### What to do
- Use sticky chapters around `120vh` to `180vh` for narrative sections.
- Animate `transform`, `opacity`, blur, clip/reveal, and color transitions.
- Build scroll-linked progress, not scroll hijacking.
- Use reduced-motion fallbacks.

### What not to do
- No full-site hard scroll snapping.
- No forced scroll-jacking.
- No giant DOM-heavy scene with dozens of constantly animating layers.
- No decorative motion that competes with reading.

## Implementation guidance

### Best build model
- Pre-render or server-render all marketing routes.
- Hydrate motion after first paint.
- Use CSS scroll-driven animations where supported.
- Use a JS fallback only where needed.

### Performance rules
- Keep chapter DOMs lean.
- Avoid layout thrashing.
- Avoid animating geometric properties when a transform will do.
- Test mobile first, not desktop only.

## Home vs subpage role split

### Homepage should answer
- Who is DotsAI?
- Why trust this agency?
- Why private AI?
- What do you build?
- Why now?
- How do I start?

### Service pages should answer
- Is this the exact service I need?
- Do you understand my use case?
- What outcomes do you deliver?
- Why should I trust you for this?

## Final recommendation
- Make the homepage cinematic.
- Make the subpages surgical.
- Let the homepage win attention.
- Let the subpages win rankings.
