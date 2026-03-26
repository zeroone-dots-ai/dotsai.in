"use client";

import dynamic from "next/dynamic";
import { useState, useRef, useCallback, useEffect } from "react";
import { useGSAP } from "@gsap/react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import SplashIntro from "@/app/components/SplashIntro";
import Nav from "@/app/components/Nav";
import Image from "next/image";

gsap.registerPlugin(ScrollTrigger);

// Heavy canvas components load client-side only
const GalaxyBackground   = dynamic(() => import("@/app/components/GalaxyBackground"),   { ssr: false });
const InfinityCompanion  = dynamic(() => import("@/app/components/InfinityCompanion"),  { ssr: false });
const QuantumCursor      = dynamic(() => import("@/app/components/QuantumCursor"),      { ssr: false });

/* ─── Magnetic Button ─── */
function MagneticButton({
  children, href, className, external = false,
}: {
  children: React.ReactNode;
  href: string;
  className?: string;
  external?: boolean;
}) {
  const ref = useRef<HTMLAnchorElement>(null);
  const onMove = (e: React.MouseEvent) => {
    if (!ref.current) return;
    const r = ref.current.getBoundingClientRect();
    const x = e.clientX - r.left - r.width  / 2;
    const y = e.clientY - r.top  - r.height / 2;
    gsap.to(ref.current, { x: x * 0.28, y: y * 0.28, duration: 0.3, ease: "power2.out" });
  };
  const onLeave = () => {
    if (ref.current) gsap.to(ref.current, { x: 0, y: 0, duration: 0.6, ease: "elastic.out(1,0.4)" });
  };
  return (
    <a
      ref={ref} href={href} className={`magnetic ${className ?? ""}`}
      onMouseMove={onMove} onMouseLeave={onLeave}
      {...(external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
    >
      {children}
    </a>
  );
}

/* ─── Dot Grid (3×3) ─── */
function DotGrid({ size = 8 }: { size?: number }) {
  const DOTS = [
    { color: "#D7CFF0" }, { color: "rgba(255,255,255,0.12)" }, { color: "rgba(255,255,255,0.12)" },
    { color: "rgba(255,255,255,0.12)" }, { color: "#C9DED4" }, { color: "rgba(255,255,255,0.12)" },
    { color: "rgba(255,255,255,0.12)" }, { color: "rgba(255,255,255,0.12)" }, { color: "#F1C6AE" },
  ];
  return (
    <div className="grid gap-1" style={{ gridTemplateColumns: `repeat(3, ${size}px)` }}>
      {DOTS.map((d, i) => (
        <div key={i} className="rounded-sm" style={{ width: size, height: size, background: d.color }} />
      ))}
    </div>
  );
}

/* ─── SERVICES DATA ─── */
const SERVICES = [
  {
    tag: "01", pillar: "D — Data",
    title: "Private AI Deployment",
    headline: "Your LLM. Your server. Your rules.",
    body: "I deploy open-source LLMs (Llama, Mistral, Gemma) directly on your infrastructure. Air-gapped, sovereign, zero data leakage. Your proprietary data trains your model — not OpenAI's next version.",
    color: "#D7CFF0",
    href: "https://private.dotsai.in",
  },
  {
    tag: "02", pillar: "O — Operations",
    title: "AI Agent Systems",
    headline: "Agents that work while you sleep.",
    body: "Custom AI agents for your exact workflow — sales, compliance, customer ops, finance. Each agent has memory, tools, and escalation logic. Built on your stack, owned by you forever.",
    color: "#C9DED4",
    href: "https://wa.me/918320065658",
  },
  {
    tag: "03", pillar: "T — Tech",
    title: "AI Web Presence",
    headline: "Full-stack web products built with AI inside.",
    body: "Not just a website — an intelligent system. AI-powered search, recommendations, dynamic content. Built fast with Next.js + AI. Deployed on your VPS or mine.",
    color: "#F1C6AE",
    href: "https://web.dotsai.in",
  },
  {
    tag: "04", pillar: "S — Strategy",
    title: "GEO AI & Local SEO",
    headline: "Be the answer AI gives your customers.",
    body: "Generative Engine Optimization — getting Claude, ChatGPT, and Perplexity to recommend your business. Structured data, llms.txt, AI-cited content architecture. The SEO of 2025.",
    color: "#BFD6EC",
    href: "https://geo.dotsai.in",
  },
];

/* ─── PROOF DATA ─── */
const PROOF = [
  { number: "70%", label: "Cost reduction", sub: "Logistics company replaced 6 SaaS tools with one private AI" },
  { number: "8L", label: "Saved per year", sub: "Annual savings after private AI replaced vendor subscriptions" },
  { number: "3 weeks", label: "Deploy time", sub: "From requirements to production private AI deployment" },
  { number: "100%", label: "Data sovereignty", sub: "Zero bytes sent to external AI providers" },
];

/* ─── MAIN PAGE ─── */
export default function Home() {
  const [splashDone, setSplashDone] = useState(false);
  const mainRef = useRef<HTMLDivElement>(null);

  const onSplashComplete = useCallback(() => setSplashDone(true), []);

  // GSAP scroll animations — run after splash is done
  useGSAP(() => {
    if (!splashDone) return;

    // Hero text entrance
    gsap.timeline({ delay: 0.1 })
      .to(".hero-eyebrow", { opacity: 1, y: 0, duration: 0.8, ease: "power3.out" })
      .to(".hero-h1",      { opacity: 1, y: 0, duration: 0.9, ease: "power3.out" }, "-=0.5")
      .to(".hero-sub",     { opacity: 1, y: 0, duration: 0.8, ease: "power3.out" }, "-=0.6")
      .to(".hero-ctas",    { opacity: 1, y: 0, duration: 0.7, ease: "power3.out" }, "-=0.5");

    // Manifesto word reveal on scroll
    const words = document.querySelectorAll<HTMLElement>(".manifesto-word");
    if (words.length) {
      gsap.from(words, {
        opacity: 0, y: 20, stagger: 0.06, duration: 0.5, ease: "power3.out",
        scrollTrigger: { trigger: "#manifesto", start: "top 70%", end: "bottom 30%", scrub: 0.5 },
      });
    }

    // Services — each slides in
    gsap.utils.toArray<HTMLElement>(".service-item").forEach((el, i) => {
      gsap.from(el, {
        opacity: 0, x: i % 2 === 0 ? -40 : 40, duration: 0.8, ease: "power3.out",
        scrollTrigger: { trigger: el, start: "top 80%" },
      });
    });

    // Proof numbers
    gsap.utils.toArray<HTMLElement>(".proof-number").forEach((el) => {
      gsap.from(el, {
        opacity: 0, scale: 0.8, duration: 0.6, ease: "back.out(1.7)",
        scrollTrigger: { trigger: el, start: "top 85%" },
      });
    });

    // Contact
    gsap.from(".contact-content", {
      opacity: 0, y: 40, duration: 0.9, ease: "power3.out",
      scrollTrigger: { trigger: "#contact", start: "top 75%" },
    });

    // Nav colour on scroll
    const nav = document.getElementById("main-nav");
    ScrollTrigger.create({
      trigger: "#hero", start: "bottom top",
      onEnter:     () => { if (nav) nav.dataset.scrolled = "true";  },
      onLeaveBack: () => { if (nav) nav.dataset.scrolled = "false"; },
    });
  }, { dependencies: [splashDone], scope: mainRef });

  const manifestoText = "I am one person. I build AI that lives on YOUR server. Your data never leaves. Your competitors never see it. This is private AI — and it changes everything.";

  return (
    <>
      {/* Splash */}
      {!splashDone && <SplashIntro onComplete={onSplashComplete} />}

      {/* Global canvas layers */}
      <GalaxyBackground />
      <InfinityCompanion />
      <QuantumCursor />

      {/* Main page — fades in after splash */}
      <div
        ref={mainRef}
        className="relative z-10 transition-opacity duration-700"
        style={{ opacity: splashDone ? 1 : 0 }}
      >
        <Nav />

        {/* ══ HERO ══ */}
        <section
          id="hero"
          className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-6 pt-28 pb-16"
        >
          {/* Plum glow behind text */}
          <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[640px] h-[420px] rounded-full pointer-events-none"
            style={{ background: "radial-gradient(ellipse, rgba(67,48,95,0.30) 0%, transparent 70%)" }}
          />

          <div className="relative z-10 text-center max-w-4xl mx-auto">
            {/* Eyebrow */}
            <div
              className="hero-eyebrow inline-flex items-center gap-3 mb-10"
              style={{ opacity: 0, transform: "translateY(12px)" }}
            >
              <DotGrid size={7} />
              <span className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase text-white/40">
                Meet Deshani · ZeroOne D.O.T.S AI
              </span>
            </div>

            {/* H1 */}
            <h1
              className="hero-h1 font-[family-name:var(--font-display)] leading-[0.9] mb-8"
              style={{ fontSize: "clamp(56px,10vw,130px)", opacity: 0, transform: "translateY(24px)", color: "#eae8f2" }}
            >
              Own Your AI.
              <br />
              <em style={{ color: "#D7CFF0" }}>Don&apos;t Rent It.</em>
            </h1>

            {/* Sub */}
            <p
              className="hero-sub text-base md:text-lg max-w-xl mx-auto mb-12 leading-relaxed"
              style={{ color: "rgba(155,149,174,0.85)", opacity: 0, transform: "translateY(16px)" }}
            >
              Built by one expert. Deployed on your server.
              <br />Your data never leaves your control.
            </p>

            {/* CTAs */}
            <div className="hero-ctas flex flex-wrap items-center justify-center gap-4" style={{ opacity: 0, transform: "translateY(12px)" }}>
              <MagneticButton
                href="#services"
                className="inline-flex items-center px-7 py-3.5 rounded-full text-sm font-medium bg-[#D7CFF0] text-[#171722] hover:brightness-110 transition-all"
              >
                → See What I Build
              </MagneticButton>
              <MagneticButton
                href="https://wa.me/918320065658"
                external
                className="inline-flex items-center px-7 py-3.5 rounded-full text-sm font-medium bg-white/[0.06] text-white hover:bg-white/[0.1] border border-white/[0.1] transition-all"
              >
                ↗ Let&apos;s Talk
              </MagneticButton>
            </div>
          </div>

          {/* Bottom logo mark */}
          <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-3 opacity-30">
            <div className="w-px h-12 bg-gradient-to-b from-white/60 to-transparent" />
            <span className="font-[family-name:var(--font-mono)] text-[9px] tracking-[0.3em] uppercase text-white/50">Scroll</span>
          </div>
        </section>

        {/* ══ MANIFESTO ══ */}
        <section id="manifesto" className="relative px-6 py-32 md:py-48">
          <div className="max-w-4xl mx-auto">
            <p className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase text-white/25 mb-10">
              // manifesto
            </p>
            <p className="font-[family-name:var(--font-display)] leading-tight text-white/90"
              style={{ fontSize: "clamp(28px,5vw,64px)" }}>
              {manifestoText.split(" ").map((word, i) => (
                <span key={i} className="manifesto-word inline-block mr-[0.28em]">{word}</span>
              ))}
            </p>
          </div>
        </section>

        {/* ══ SERVICES ══ */}
        <section id="services" className="relative px-6 py-24 md:py-36">
          <div className="max-w-5xl mx-auto">
            <div className="mb-20">
              <p className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase text-white/25 mb-4">
                // what I build
              </p>
              <h2 className="font-[family-name:var(--font-display)] text-white/90"
                style={{ fontSize: "clamp(32px,5vw,72px)", lineHeight: 1 }}>
                Four Pillars.
                <br /><span style={{ color: "#D7CFF0" }}>One Expert.</span>
              </h2>
            </div>

            <div className="space-y-24">
              {SERVICES.map((s, i) => (
                <div
                  key={s.tag}
                  className={`service-item grid md:grid-cols-2 gap-12 items-center ${i % 2 === 1 ? "md:grid-flow-col-dense" : ""}`}
                >
                  <div className={i % 2 === 1 ? "md:col-start-2" : ""}>
                    <div className="flex items-center gap-3 mb-6">
                      <span className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.2em] text-white/25">{s.tag}</span>
                      <span className="h-px flex-1 max-w-[40px]" style={{ background: s.color + "60" }} />
                      <span className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.18em] uppercase" style={{ color: s.color }}>
                        {s.pillar}
                      </span>
                    </div>
                    <h3 className="font-[family-name:var(--font-display)] text-white/90 mb-3"
                      style={{ fontSize: "clamp(24px,3.5vw,44px)", lineHeight: 1.1 }}>
                      {s.title}
                    </h3>
                    <p className="text-white/55 text-sm mb-4 font-medium italic">{s.headline}</p>
                    <p className="text-white/40 text-sm leading-relaxed mb-8">{s.body}</p>
                    <MagneticButton
                      href={s.href}
                      external
                      className="service-link inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-xs font-medium border transition-all hover:bg-white/[0.05]"
                      style={{ borderColor: s.color + "40", color: s.color } as React.CSSProperties}
                    >
                      Explore → {s.title}
                    </MagneticButton>
                  </div>

                  {/* Visual card */}
                  <div
                    className={`glass rounded-2xl p-8 aspect-square max-w-sm mx-auto w-full flex items-center justify-center ${i % 2 === 1 ? "md:col-start-1 md:row-start-1" : ""}`}
                    style={{ borderColor: s.color + "20" } as React.CSSProperties}
                  >
                    <div className="text-center">
                      <div className="w-16 h-16 rounded-2xl mx-auto mb-4 flex items-center justify-center"
                        style={{ background: s.color + "15" }}>
                        <span className="font-[family-name:var(--font-mono)] text-2xl font-bold" style={{ color: s.color }}>
                          {s.pillar[0]}
                        </span>
                      </div>
                      <p className="font-[family-name:var(--font-display)] text-white/60 text-xl">{s.title}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ══ PROOF ══ */}
        <section id="proof" className="relative px-6 py-24 md:py-36">
          <div className="max-w-5xl mx-auto">
            <div className="mb-16">
              <p className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase text-white/25 mb-4">
                // outcomes
              </p>
              <h2 className="font-[family-name:var(--font-display)] text-white/90"
                style={{ fontSize: "clamp(28px,4vw,56px)", lineHeight: 1 }}>
                Real results.
                <br /><span style={{ color: "#B28743" }}>Real numbers.</span>
              </h2>
            </div>

            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {PROOF.map((p) => (
                <div key={p.number} className="proof-number glass rounded-2xl p-6">
                  <div
                    className="font-[family-name:var(--font-display)] mb-1"
                    style={{ fontSize: "clamp(36px,5vw,56px)", lineHeight: 1, color: "#D7CFF0" }}
                  >
                    {p.number}
                  </div>
                  <div className="text-white/60 text-sm font-medium mb-2">{p.label}</div>
                  <div className="text-white/30 text-xs leading-relaxed">{p.sub}</div>
                </div>
              ))}
            </div>

            {/* Case study hint */}
            <div className="mt-12 glass rounded-2xl p-8 border border-[#B28743]/15">
              <div className="flex items-start gap-4">
                <div className="w-8 h-8 rounded-full bg-[#B28743]/15 flex-shrink-0 flex items-center justify-center text-[#B28743] text-xs">↗</div>
                <div>
                  <p className="text-white/70 text-sm font-medium mb-1">Logistics Company · Mumbai</p>
                  <p className="text-white/40 text-sm leading-relaxed">
                    Replaced Salesforce, Zendesk, and 4 other SaaS tools with a single private AI.
                    Runs on-premise. Costs ₹0/month in vendor fees after setup.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ══ CONTACT ══ */}
        <section id="contact" className="relative px-6 py-24 md:py-40">
          <div className="max-w-3xl mx-auto text-center contact-content">
            <p className="font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase text-white/25 mb-8">
              // let&apos;s build
            </p>
            <h2 className="font-[family-name:var(--font-display)] text-white/90 mb-6"
              style={{ fontSize: "clamp(36px,6vw,80px)", lineHeight: 0.95 }}>
              Ready to own
              <br />your AI?
            </h2>
            <p className="text-white/40 text-base mb-12 max-w-md mx-auto leading-relaxed">
              Direct line. No sales team. No forms. Just a conversation with the person who&apos;ll actually build it.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-4">
              <MagneticButton
                href="https://wa.me/918320065658"
                external
                className="inline-flex items-center gap-2 px-8 py-4 rounded-full text-sm font-medium bg-[#D7CFF0] text-[#171722] hover:brightness-110 transition-all"
              >
                ↗ WhatsApp — Direct
              </MagneticButton>
              <MagneticButton
                href="mailto:aamdhanee.dev@gmail.com"
                external
                className="inline-flex items-center gap-2 px-8 py-4 rounded-full text-sm font-medium bg-white/[0.06] text-white hover:bg-white/[0.1] border border-white/[0.1] transition-all"
              >
                ✉ Email Me
              </MagneticButton>
            </div>

            <div className="mt-20 pt-12 border-t border-white/[0.05] flex flex-col sm:flex-row items-center justify-between gap-6 text-white/20 text-xs font-[family-name:var(--font-mono)]">
              <span>© 2025 ZeroOne D.O.T.S AI · Meet Deshani</span>
              <div className="flex items-center gap-4">
                <DotGrid size={5} />
                <span>D · O · T · S</span>
              </div>
            </div>
          </div>
        </section>
      </div>
    </>
  );
}
