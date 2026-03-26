# Scroll Specification — dotsai.in

> Per-section GSAP ScrollTrigger configuration + animation timelines
> Total scroll distance: ~2000vh (6 sections × ~300-400vh each)

---

## Setup

```tsx
// src/lib/gsap.ts
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
gsap.registerPlugin(ScrollTrigger)
export { gsap, ScrollTrigger }

// src/components/scroll/CompartmentScroll.tsx
'use client'
import { useEffect } from 'react'
import { gsap, ScrollTrigger } from '@/lib/gsap'
import { useGSAP } from '@gsap/react'

export function CompartmentScroll() {
  useGSAP(() => {
    // All ScrollTrigger inits here
    // Auto-cleaned up when component unmounts
  })
  return null
}
```

---

## Section 1: Hero

**Config:**
```js
const heroTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#s-hero',
    pin: true,
    scrub: 2,              // dreamy, for 3D
    start: 'top top',
    end: '+=400%',         // 4x viewport scroll
  }
})
```

**Timeline:**
```js
heroTl
  // Phase 1: Entrance (scroll 0–25%)
  .fromTo('#hero-label',    { opacity: 0, y: 20 }, { opacity: 1, y: 0 }, 0)
  .fromTo('#hero-headline', { opacity: 0, y: 60 }, { opacity: 1, y: 0 }, 0.1)
  .fromTo('#hero-sub',      { opacity: 0 },        { opacity: 1 },       0.3)
  .fromTo('#hero-cta',      { opacity: 0, y: 20 }, { opacity: 1, y: 0 }, 0.4)
  // Phase 2: Hold (scroll 25–75%) — galaxy rotates, user reads
  // Phase 3: Exit (scroll 75–100%)
  .to('#hero-headline', { opacity: 0, y: -60 }, 0.8)
  .to('#hero-sub',      { opacity: 0 },         0.85)
  .to('#hero-cta',      { opacity: 0 },         0.85)

// Galaxy camera movement (separate, scrub: 2)
gsap.to('#galaxy-camera', {
  z: 3, y: 1,
  scrollTrigger: { trigger: '#s-hero', start: 'top top', end: '+=400%', scrub: 2 }
})
```

**Section transition (dark → cream):**
```js
gsap.to('#s-hero', {
  backgroundColor: '#FDFCFA',
  scrollTrigger: {
    trigger: '#s-manifesto',
    start: 'top bottom',
    end: 'top top',
    scrub: true
  }
})
```

---

## Section 2: Manifesto

**Config:**
```js
const manifestoTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#s-manifesto',
    pin: true,
    scrub: 1,
    start: 'top top',
    end: '+=150%',
  }
})
```

**Timeline (word-by-word reveal):**
```js
const words = gsap.utils.toArray<HTMLElement>('.manifesto-word')
words.forEach((word, i) => {
  manifestoTl.fromTo(word,
    { opacity: 0.08, filter: 'blur(4px)' },
    { opacity: 1, filter: 'blur(0px)', duration: 0.1 },
    i * (0.8 / words.length)   // distribute across 80% of timeline
  )
})
// Fade entire block out at end
manifestoTl.to('#manifesto-block', { opacity: 0 }, 0.9)
```

---

## Section 3: Services

**Config:**
```js
const servicesTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#s-services',
    pin: true,
    scrub: 1,
    start: 'top top',
    end: '+=400%',
  }
})
```

**Timeline (4 services, each takes 25% of timeline):**
```js
const services = ['#service-1', '#service-2', '#service-3', '#service-4']

services.forEach((id, i) => {
  const start = i * 0.22
  const end = start + 0.22

  servicesTl
    // Service enters from right
    .fromTo(`${id}`, { opacity: 0, x: 80 }, { opacity: 1, x: 0 }, start)
    // Label appears
    .fromTo(`${id} .service-label`, { opacity: 0, y: 10 }, { opacity: 1, y: 0 }, start + 0.02)
    // Name appears
    .fromTo(`${id} .service-name`, { opacity: 0, y: 20 }, { opacity: 1, y: 0 }, start + 0.05)
    // Tagline + description
    .fromTo(`${id} .service-desc`, { opacity: 0 }, { opacity: 1 }, start + 0.1)
    // CTA arrow
    .fromTo(`${id} .service-cta`, { opacity: 0, x: -10 }, { opacity: 1, x: 0 }, start + 0.15)
    // Exit (overlap with next service entrance)
    .to(`${id}`, { opacity: 0, x: -80 }, end - 0.05)
})
```

**Section transition (cream → dark):**
```js
gsap.to('#s-services', {
  backgroundColor: '#0c0c14',
  scrollTrigger: {
    trigger: '#s-proof',
    start: 'top bottom',
    end: 'top top',
    scrub: true
  }
})
```

---

## Section 4: Proof

**Config:**
```js
const proofTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#s-proof',
    pin: true,
    scrub: 1,
    start: 'top top',
    end: '+=150%',
  }
})
```

**Timeline:**
```js
proofTl
  .fromTo('#proof-industry', { opacity: 0 }, { opacity: 1 }, 0)
  .fromTo('#proof-metric-1', { opacity: 0, y: 30 }, { opacity: 1, y: 0 }, 0.15)
  .fromTo('#proof-metric-2', { opacity: 0, y: 30 }, { opacity: 1, y: 0 }, 0.25)
  .fromTo('#proof-metric-3', { opacity: 0, y: 30 }, { opacity: 1, y: 0 }, 0.35)
  .fromTo('#proof-quote',    { opacity: 0 }, { opacity: 1 }, 0.55)
  .fromTo('#proof-badge',    { opacity: 0 }, { opacity: 1 }, 0.7)

// Counters animate on scroll (not scrubbed — fires once)
ScrollTrigger.create({
  trigger: '#s-proof',
  start: 'top 60%',
  onEnter: () => animateCounters()
})

function animateCounters() {
  gsap.to('#counter-1', { innerText: 70,  snap: { innerText: 1 }, duration: 1.5 })
  gsap.to('#counter-2', { innerText: 800000, snap: { innerText: 1000 }, duration: 2 })
  gsap.to('#counter-3', { innerText: 99,  snap: { innerText: 1 }, duration: 1.2 })
}
```

**Section transition (dark → cream):**
```js
gsap.to('#s-proof', {
  backgroundColor: '#FDFCFA',
  scrollTrigger: {
    trigger: '#s-subdomains',
    start: 'top bottom',
    end: 'top top',
    scrub: true
  }
})
```

---

## Section 5: Subdomain Gateway

**Config:**
```js
const subTl = gsap.timeline({
  scrollTrigger: {
    trigger: '#s-subdomains',
    pin: true,
    scrub: 1,
    start: 'top top',
    end: '+=150%',
  }
})
```

**Timeline:**
```js
subTl
  .fromTo('#sub-headline', { opacity: 0, y: 40 }, { opacity: 1, y: 0 }, 0)
  .fromTo('#sub-1', { opacity: 0, x: -30 }, { opacity: 1, x: 0 }, 0.2)
  .fromTo('#sub-2', { opacity: 0, x: -30 }, { opacity: 1, x: 0 }, 0.3)
  .fromTo('#sub-3', { opacity: 0, x: -30 }, { opacity: 1, x: 0 }, 0.4)
  .fromTo('#sub-4', { opacity: 0, x: -30 }, { opacity: 1, x: 0 }, 0.5)
```

---

## Section 6: Contact (Free Scroll)

No ScrollTrigger pin. Simple fade-in animations:

```js
// Fires when section enters viewport
gsap.fromTo('#s-contact .contact-inner',
  { opacity: 0, y: 40 },
  {
    opacity: 1, y: 0,
    scrollTrigger: {
      trigger: '#s-contact',
      start: 'top 70%',
      toggleActions: 'play none none reverse'
    }
  }
)
```

---

## Mobile Fallback

```js
ScrollTrigger.matchMedia({
  // Desktop + tablet: full compartment scroll
  '(min-width: 768px)': () => {
    initHeroScroll()
    initManifestoScroll()
    initServicesScroll()
    initProofScroll()
    initSubdomainScroll()
  },

  // Mobile: simple fade-ins, no pins
  '(max-width: 767px)': () => {
    const sections = ['#s-hero', '#s-manifesto', '#s-services', '#s-proof', '#s-subdomains']
    sections.forEach(id => {
      gsap.fromTo(id,
        { opacity: 0, y: 30 },
        { opacity: 1, y: 0, scrollTrigger: { trigger: id, start: 'top 80%' } }
      )
    })
    // Individual elements still animate
    initCounters()
  }
})
```

---

## Performance Checklist

- [ ] `will-change: transform` on all animated elements
- [ ] Only animate `transform` and `opacity` (no layout props)
- [ ] `ScrollTrigger.refresh()` after fonts load
- [ ] Kill all ScrollTrigger instances on page unmount
- [ ] `pinnedContainer` set for any nested pins
- [ ] Disable galaxy animation when section out of viewport (IntersectionObserver)
- [ ] `scrub` values never exceed 2 except on galaxy (prevent lag feeling)
