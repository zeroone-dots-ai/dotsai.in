# Research Findings — dotsai.in Premium Revamp

> Generated via NotebookLM deep research (5 iterations)
> Date: 2026-03-26

---

## Thread A: 3D White Milky Way Galaxy (Three.js)

### Core Technique
Use **BufferGeometry + ShaderMaterial** — maximum performance, visual quality.
- Do NOT use pre-rendered video for the hero background. Build it live in WebGL.
- Use React Three Fiber (R3F) for Next.js integration.
- Dynamically import to avoid SSR: `dynamic(() => import(), { ssr: false })`

### Particle Counts
| Device | Count |
|--------|-------|
| Desktop | 80,000–100,000 |
| Mobile (≤768px) | 15,000–20,000 |
| Adaptive | Use `navigator.hardwareConcurrency` |

### Color Palette (White/Silver Galaxy)
| Zone | Color | Alpha |
|------|-------|-------|
| Inner core | `#ffffff` (pure white) | High |
| Mid disk | `#e0e0f0` (silver-white) | Medium |
| Outer edges | `#8888bb` (silver-blue) | Low, tapered |
| Nebula clouds | `#fafaf8` (cream-white) | 0.05–0.15 |

### Spiral Arm Algorithm
```js
const branchAngle = (i % params.branches) / params.branches * Math.PI * 2
const spinAngle = radius * params.spin
const angle = branchAngle + spinAngle
positions[i3    ] = Math.cos(angle) * radius + randomX
positions[i3 + 1] = randomY * 0.3   // flat disk
positions[i3 + 2] = Math.sin(angle) * radius + randomZ
```
- 3 spiral branches
- Spin factor: 1.0
- Randomness power: 3 (clusters particles toward spiral arms)

### Glow Effect (Fragment Shader)
```glsl
void main() {
  float strength = distance(gl_PointCoord, vec2(0.5));
  strength = 1.0 - strength;
  strength = pow(strength, 10.0);  // tight bloom
  gl_FragColor = vec4(vColor, strength);
}
```
- THREE.AdditiveBlending — stars bloom when overlapping
- depthWrite: false — correct transparency stacking

### Center Glow (Galactic Core)
- THREE.Sprite or billboard PlaneGeometry
- Radial gradient texture: white center → transparent
- Size: 0.5–1.0 units

### Nebula Clouds (Secondary Particle System)
- Count: 500–1,000 particles
- Size: 0.01–0.05
- Custom shader for Gaussian blur
- Color: `#fafaf8` at 0.05–0.15 alpha
- Distributed around galactic center + arm midpoints

### GSAP ScrollTrigger Camera
```js
// Camera pulls back as user scrolls
gsap.to(camera.position, { z: 3, y: 1, scrollTrigger: { scrub: 1.5 } })
// Galaxy rotates
gsap.to(galaxyGroup.rotation, { y: Math.PI * 0.5, scrollTrigger: { scrub: 2 } })
```

### Performance Rules
- Limit canvas to hero section height ONLY
- IntersectionObserver → pause when out of viewport
- useMemo for geometry (prevent re-creation)
- dispose() on unmount
- dpr={[1, 1.5]} — limit pixel ratio
- gl={{ antialias: false }} — performance

---

## Thread B: Compartment Scroll Architecture

### GSAP vs Alternatives — Final Verdict
**GSAP ScrollTrigger** is the gold standard. Unmatched premium feel and developer control.

### scrub Value Guide
| Value | Feel | Use Case |
|-------|------|----------|
| `true` | 1:1 robotic | Never use |
| `0.5` | Very tight | Simple fade-ins |
| `1` | Standard smooth | Most sections |
| `2` | Dreamy, floaty | Galaxy rotation, 3D |
| `4+` | Very slow | Large transforms |

### Section Duration Formula
- Simple reveals: `end: '+=150%'`
- Standard sequences: `end: '+=300%'`
- Complex (hero, services): `end: '+=400%'`
- Gallery swipes: `end: '+=600%'`

### Per-Section Spec

| Section | Pin | Scrub | End | Key Animations |
|---------|-----|-------|-----|----------------|
| 1 Hero | yes | 2 | +=400% | Galaxy rotates, headline fades in, CTA reveals |
| 2 Manifesto | yes | 1 | +=150% | Words reveal 0.08→1.0 opacity one by one |
| 3 Services | yes | 1 | +=400% | Each service slides in, 70/30 layout |
| 4 Proof | yes | 1 | +=150% | Counters animate 0→final, quote fades |
| 5 Subdomains | yes | 1 | +=150% | Cards orbit in, hover color fill |
| 6 Contact | no | — | natural | Simple fade-in, no scroll tricks |

### Section Transitions
- Hero → Manifesto: `background: #06060a → #FDFCFA` (dark→cream, cinematic)
- Manifesto → Services: stays cream
- Services → Proof: cream → `#0c0c14` (dark return)
- Proof → Subdomains: dark → cream
- Subdomains → Contact: stays cream

### Word-by-Word Reveal (Manifesto)
```js
const words = document.querySelectorAll('.manifesto-word')
words.forEach((word, i) => {
  manifestoTl.fromTo(word,
    { opacity: 0.08, filter: 'blur(4px)' },
    { opacity: 1, filter: 'blur(0px)', duration: 0.1 },
    i * 0.05
  )
})
```

### Mobile Fallback
- Disable `pin: true` on < 480px (iOS rubber-band issues)
- Use CSS `scroll-snap-type: y mandatory` on mobile
- Keep GSAP fade-in animations (not pin/scrub)
- `ScrollTrigger.matchMedia()` for breakpoint handling

---

## Thread C: Solopreneur Positioning

### Levels.io Model Applied to Meet
- Lead with outcomes, not tech stack
- Personal brand = business brand
- Simple, direct language (no jargon)
- Social proof via specific numbers
- One person = trust + speed + accountability

### Positioning Statement
"I build private AI that your business owns. One expert. Your server. Your data."

### Hero Headline (KEEP current)
**"Own Your AI. Don't Rent It."** — ownership vs rental tension. Clear, visceral. Works.

Sub-line: **"Built by one expert. Deployed on your server."**

### Service Tier Ranking (by conversion)
1. **Private AI** — highest intent, enterprise buyers
2. **AI Web** — SME market, immediate ROI visible
3. **GEO AI** — emerging, growing demand
4. **Platform** — developer/builder segment

### India-Specific Advantages to Emphasize
- Data stays in India (compliance/sovereignty)
- Hindi/Gujarati/regional language AI
- Offline capability (infrastructure unreliable in Tier 2/3 cities)
- "Affordable enterprise AI" positioning

### What NOT to Say
- No "LLMs, RAG, vector databases" jargon
- No "enterprise-grade" buzzwords
- No "innovative" or "cutting-edge"
- Just outcomes + ownership + speed

---

## Thread D: Premium Editorial Design

### Anti-Bento Philosophy
Full-width, one idea per viewport, silence as design, type does the work.

### Light Cream + Dark Hero Hybrid (Proven Pattern)
Used by: Linear, Vercel, Craft, Resend

```
Dark hero → cinematic → Light cream body
```

### D.O.T.S. Color → Service Mapping
| Color | D.O.T.S. | Service | Subdomain |
|-------|----------|---------|-----------|
| Lavender `#C8B6FF` | Data | Private AI | private.dotsai.in |
| Mint `#B8E0D2` | Operations | Platform/Automation | platform.dotsai.in |
| Peach `#FFCDB2` | Tech | AI Web | web.dotsai.in |
| Sky Blue `#A2D2FF` | Strategy | GEO AI | geo.dotsai.in |

### Color Usage Rule
- 10-20% coverage as accents ONLY
- Applied as: text color, left border, glow, hover fill
- NEVER as full background

### Glass Morphism CTA Button
```css
backdrop-filter: blur(12px);
background: rgba(255, 255, 255, 0.03);
border: 1px solid rgba(255, 255, 255, 0.06);
/* hover: warmth gradient (peach → pink → lavender) */
```

### Typography Scale
| Element | Font | Size (desktop) | Size (mobile) |
|---------|------|----------------|---------------|
| H1/Display | Instrument Serif | 100–140px | 48–64px |
| H2 | Instrument Serif | 56–80px | 36–48px |
| H3 | DM Sans 600 | 32–40px | 24–28px |
| Body | DM Sans 400 | 18–20px | 16–17px |
| Label | Space Mono | 11–13px UPPERCASE | 10–11px |
| Caption | DM Sans | 14px | 13px |
| Quote | DM Sans italic | 20px | 17px |
| Numbers (proof) | Space Mono | 48–64px | 32–40px |

---

## Thread E: Assets Needed

### 3D Animated Hero — Build in WebGL (NOT video)
- Built programmatically with React Three Fiber
- White milky way galaxy, 80K particles desktop
- No video file needed for hero

### 3D Service Icons (Optional)
- If used: WebP with transparent bg OR GLB/GLTF
- Must use D.O.T.S. accent colors per service
- Editorial philosophy says: type can do this work alone

### 3D Meet Deshani Avatar (For personal brand)
- Format options:
  - Real-time: GLB with Draco compression (in R3F canvas)
  - Pre-rendered: WebM with alpha channel (loops seamlessly)
  - Still: High-quality WebP with transparent bg
- Style: Polished, minimalist — blends with dark (#06060a) or cream (#FDFCFA)
- Generate from: Freepik (Playwright automation) or Higgsfield AI

### Freepik Asset Generation (Playwright)
Use Playwright to:
1. Navigate to freepik.com/ai/image-generator
2. Generate: 3D abstract galaxy/space textures (white/silver nebula)
3. Generate: 3D service concept visuals per D.O.T.S. pillar
4. Generate: Professional 3D avatar for Meet
5. Download as WebP/PNG

---

## Implementation Order (from Research)

1. **Phase 1:** CSS design system + typography (globals.css tokens)
2. **Phase 2:** GSAP ScrollTrigger layout (6 sections, pin/scrub)
3. **Phase 3:** React Three Fiber galaxy hero (Three.js milky way)
4. **Phase 4:** Content + copy + subdomain routing
5. **Phase 5:** Assets from Freepik/Higgsfield
6. **Phase 6:** Docker deployment to VPS
