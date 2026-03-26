# Architecture — dotsai.in

> Subdomain map, page structure, component tree, routing

---

## Domain Map

```
dotsai.in                    ← THIS SITE (solopreneur gateway)
  ├── geo.dotsai.in          ← GEO AI / Local SEO service site
  ├── private.dotsai.in      ← Private AI deployment service site
  ├── platform.dotsai.in     ← Redirect → platform.dotsai.cloud
  └── web.dotsai.in          ← AI Web Presence service site
```

## Project Structure

```
/Users/meetdeshani/Desktop/dotsai.in/
├── .planning/                    # Research + specs (this folder)
├── public/
│   ├── brand/                    # Logos (copy from web.dotsai.cloud/public/brand/)
│   │   ├── zeroone-dark-icon.svg
│   │   ├── zeroone-dark-horizontal.svg
│   │   └── zeroone-dark-circle.svg
│   ├── assets/
│   │   ├── hero/                 # Galaxy textures (from Freepik)
│   │   ├── services/             # 3D service visuals (WebP, transparent bg)
│   │   ├── avatar/               # Meet's 3D avatar (WebP or WebM)
│   │   └── og-image.png          # Social sharing image
├── src/
│   ├── app/
│   │   ├── layout.tsx            # Root layout (fonts, metadata, grain overlay)
│   │   ├── page.tsx              # Main page (assembles all sections)
│   │   └── globals.css           # Design tokens + base styles
│   ├── components/
│   │   ├── webgl/
│   │   │   ├── MilkyWayGalaxy.tsx    # Three.js BufferGeometry particle system
│   │   │   ├── GalaxyCanvas.tsx      # R3F Canvas wrapper (no SSR)
│   │   │   └── shaders/
│   │   │       ├── galaxy.vert.glsl  # Vertex shader
│   │   │       └── galaxy.frag.glsl  # Fragment shader (circular glow)
│   │   ├── sections/
│   │   │   ├── Hero.tsx              # Dark, full-bleed, galaxy + headline
│   │   │   ├── Manifesto.tsx         # Word-by-word reveal, cream bg
│   │   │   ├── Services.tsx          # Pinned service reveal, 70/30 layout
│   │   │   ├── Proof.tsx             # Dark bg, animated counters + case
│   │   │   ├── SubdomainGateway.tsx  # Links to service subdomains
│   │   │   └── Contact.tsx           # WhatsApp + Cal.com, no form
│   │   ├── ui/
│   │   │   ├── GlassButton.tsx       # Glass-morphism CTA button
│   │   │   ├── Nav.tsx               # Minimal sticky nav
│   │   │   ├── Footer.tsx            # Minimal footer
│   │   │   └── FilmGrain.tsx         # SVG turbulence overlay
│   │   └── scroll/
│   │       └── CompartmentScroll.tsx # GSAP ScrollTrigger init + cleanup
│   └── lib/
│       ├── motion.ts             # Reused from web.dotsai.cloud
│       └── gsap.ts              # GSAP + ScrollTrigger registration
├── Dockerfile
├── docker-compose.yml
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Page Sections (in order)

```
page.tsx
  ├── <Nav />                    # Fixed top, transparent on hero
  ├── <Hero />                   # Section 1 — dark, galaxy, headline
  ├── <Manifesto />              # Section 2 — cream, word reveal
  ├── <Services />               # Section 3 — cream, pinned service stack
  ├── <Proof />                  # Section 4 — dark, counters
  ├── <SubdomainGateway />       # Section 5 — cream, subdomain links
  ├── <Contact />                # Section 6 — free scroll, CTA
  └── <Footer />                 # Minimal
```

## Component Details

### Hero.tsx
- Background: `#06060a` (deep black)
- GalaxyCanvas fills full section
- Headline: Instrument Serif 100-140px, centered
- Sub-line: DM Sans 20px
- CTA: GlassButton component
- Scroll indicator: "scroll to explore" at bottom

### Manifesto.tsx
- Background: `#FDFCFA` (cream)
- Single Instrument Serif 64-80px text block
- Words split into spans with class `manifesto-word`
- GSAP scrubs opacity 0.08 → 1.0 per word
- Optional: thin left border in aurora gradient

### Services.tsx
- Background: `#FDFCFA`
- 4 service sub-sections (one per GSAP pin step)
- Layout: 70% left (large type) / 30% right (visual)
- Label: Space Mono uppercase, D.O.T.S. color
- Service name: Instrument Serif 48-64px
- Tagline: DM Sans 20px
- Arrow link: → subdomain URL

### Proof.tsx
- Background: `#0c0c14` (dark return)
- 3 metrics: Space Mono 48-64px, animate 0 → final
- Source label: DM Sans caption
- Case quote: DM Sans italic 20px

### SubdomainGateway.tsx
- Background: `#FDFCFA`
- 4 subdomain cards (full-width stacked or 4-up grid)
- Hover: D.O.T.S. color fill
- Click: navigate to subdomain

### Contact.tsx
- Minimal: Meet's name + 1-line tagline
- 2 buttons: WhatsApp + Cal.com
- Background: `#FDFCFA`
- No contact form (solopreneur direct model)

## GSAP ScrollTrigger Init Pattern

```tsx
// scroll/CompartmentScroll.tsx
useEffect(() => {
  const ctx = gsap.context(() => {
    // Hero
    const heroTl = gsap.timeline({
      scrollTrigger: { trigger: '#s-hero', pin: true, scrub: 2, end: '+=400%' }
    })
    heroTl
      .to('#hero-headline', { opacity: 1, y: 0 })
      .to('#hero-sub', { opacity: 1 }, '-=0.5')
      .to('#hero-cta', { opacity: 1, y: 0 }, '-=0.3')

    // Section color transition: dark → cream
    gsap.to('#s-hero', {
      backgroundColor: '#FDFCFA',
      scrollTrigger: { trigger: '#s-manifesto', start: 'top bottom', end: 'top top', scrub: true }
    })

    // Manifesto words
    const words = gsap.utils.toArray('.manifesto-word')
    const manifestoTl = gsap.timeline({
      scrollTrigger: { trigger: '#s-manifesto', pin: true, scrub: 1, end: '+=150%' }
    })
    words.forEach((word: any, i: number) => {
      manifestoTl.fromTo(word,
        { opacity: 0.08, filter: 'blur(4px)' },
        { opacity: 1, filter: 'blur(0px)' },
        i * 0.05
      )
    })
    // ... (services, proof, subdomains)
  })
  return () => ctx.revert()  // cleanup on unmount
}, [])
```

## Deployment

| Item | Value |
|------|-------|
| VPS | 72.62.229.16 (Hostinger) |
| Port | 3025 |
| Container | `dotsai-in` |
| Nginx config | `/etc/nginx/sites-available/dotsai.in` |
| SSL | Let's Encrypt (Certbot) |
| Build | `docker build -t dotsai-in .` |
| Run | `docker run -d -p 3025:3025 --name dotsai-in dotsai-in` |

## NPM Packages

```json
{
  "dependencies": {
    "next": "15.x",
    "react": "19.x",
    "react-dom": "19.x",
    "three": "latest",
    "@react-three/fiber": "latest",
    "@react-three/drei": "latest",
    "gsap": "^3.x",
    "@gsap/react": "latest",
    "framer-motion": "^12.x",
    "tailwindcss": "^4.x",
    "lucide-react": "latest"
  },
  "devDependencies": {
    "typescript": "^5.x",
    "@types/three": "latest",
    "lil-gui": "latest"
  }
}
```
