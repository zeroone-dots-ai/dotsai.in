# Assets Plan — dotsai.in

> 3D images, 3D animated video, and asset generation strategy

---

## Asset Generation Strategy

### Tools
| Tool | Purpose |
|------|---------|
| **Freepik AI (Playwright)** | 3D static images — service visuals, avatar |
| **Higgsfield AI** | 3D animated video — hero loop, service animations |
| **Three.js (in-code)** | Live 3D — white milky way galaxy (no pre-rendered needed) |

---

## Assets Needed

### A. Hero Galaxy — BUILT IN CODE (Three.js)
No static asset needed. Programmatic WebGL milky way.

### B. 3D Service Visuals (Freepik — WebP transparent)

| Service | Visual Concept | D.O.T.S. Color |
|---------|---------------|----------------|
| Private AI | A glowing server/circuit in silver-white | Lavender `#C8B6FF` |
| AI Web | A 3D floating website interface | Peach `#FFCDB2` |
| GEO AI | A 3D globe with AI signal waves | Sky Blue `#A2D2FF` |
| Platform | Abstract 3D gear + neural network | Mint `#B8E0D2` |

**Freepik Prompts:**
1. `3D render of a glowing server module, white and silver tones, transparent background, minimalist, premium tech aesthetic`
2. `3D floating website interface card, clean white render, lavender glow, transparent background, ultra-realistic`
3. `3D earth globe with digital signal waves, blue and white, transparent background, minimalist tech`
4. `3D abstract neural network gear, mint green and white tones, transparent background, premium`

**Spec:** WebP, transparent background, 800×800px minimum, 72dpi

### C. Meet Deshani 3D Avatar

**Concept:** Professional, minimal 3D rendered portrait — NOT cartoon. Photorealistic or high-quality stylized.
**Format:** WebP transparent bg for static use, WebM alpha loop for animated version

**Freepik Prompt:**
`Professional 3D rendered male portrait, Indian entrepreneur, minimalist style, dark background, photorealistic quality, looking slightly right`

**Usage:** Contact section and/or About bio blurb

### D. 3D Animated Video (Higgsfield AI)

**Video 1 — Hero Background Loop (optional supplement to Three.js galaxy)**
- Concept: Milky way spiral galaxy in white/silver, slow rotation, cinematic
- Format: WebM with alpha OR MP4 (dark bg), loop seamlessly
- Duration: 8-12 seconds
- Resolution: 1920×1080 minimum

**Video 2 — Service Showcase Loop**
- Concept: Abstract AI neural network animation, white particles on dark
- Format: WebM loop, 6-8 seconds
- Usage: Background for Proof section

**Higgsfield Prompt Template:**
`Cinematic 3D animation of a white milky way spiral galaxy slowly rotating, silver luminous particles, deep space background, ultra-premium quality, seamless loop, 8 seconds`

---

## Freepik Playwright Automation

```bash
# Script will:
# 1. Navigate to freepik.com AI image generator
# 2. Input each prompt
# 3. Generate and download each asset
# 4. Save to public/assets/services/ and public/assets/avatar/

# Run: node scripts/generate-assets.js
```

---

## Asset File Map

```
public/
├── brand/
│   ├── zeroone-dark-icon.svg
│   ├── zeroone-dark-horizontal.svg
│   └── zeroone-dark-circle.svg
├── assets/
│   ├── services/
│   │   ├── private-ai.webp       # Freepik 3D server visual
│   │   ├── ai-web.webp           # Freepik 3D website interface
│   │   ├── geo-ai.webp           # Freepik 3D globe
│   │   └── platform.webp         # Freepik 3D neural gear
│   ├── avatar/
│   │   ├── meet-3d.webp          # Freepik 3D avatar (static)
│   │   └── meet-3d.webm          # Higgsfield animated loop
│   ├── video/
│   │   ├── hero-galaxy.webm      # Higgsfield galaxy loop (optional)
│   │   └── proof-bg.webm         # Higgsfield neural animation
│   └── og-image.png              # Social sharing image (1200×630)
```
