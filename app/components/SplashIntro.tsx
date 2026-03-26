"use client";
import { useState, useEffect } from "react";
import Image from "next/image";

/*
  Splash Intro — adapted from web.dotsai.cloud SplashIntro.tsx
  Sequence:
  1. Logo icon fades + scales in (0→600ms)
  2. "ZeroOne D.O.T.S AI" types letter-by-letter (600ms→1900ms)
  3. Tagline fades in (hold phase)
  4. Scale up + fade out revealing page (exit)
*/

export default function SplashIntro({ onComplete }: { onComplete: () => void }) {
  const [phase, setPhase] = useState<"logo" | "typing" | "hold" | "exit" | "done">("logo");
  const [visibleChars, setVisibleChars] = useState(0);
  const text = "ZeroOne D.O.T.S AI";

  useEffect(() => {
    const t1 = setTimeout(() => setPhase("typing"), 600);
    const t2 = setTimeout(() => {
      let i = 0;
      const interval = setInterval(() => {
        i++;
        setVisibleChars(i);
        if (i >= text.length) {
          clearInterval(interval);
          setTimeout(() => setPhase("hold"), 250);
        }
      }, 60);
      return () => clearInterval(interval);
    }, 700);
    const t3 = setTimeout(() => setPhase("exit"), 2400);
    const t4 = setTimeout(() => { setPhase("done"); onComplete(); }, 3100);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); clearTimeout(t4); };
  }, [onComplete]);

  if (phase === "done") return null;

  return (
    <div
      className={`fixed inset-0 z-[200] flex flex-col items-center justify-center bg-[#06060a] transition-all duration-700 ${
        phase === "exit" ? "opacity-0 scale-110" : "opacity-100 scale-100"
      }`}
      style={{ willChange: "opacity, transform" }}
    >
      {/* 3x3 Dot Grid Logo */}
      <div
        className={`transition-all duration-500 ${
          phase === "logo" ? "opacity-0 scale-75" : "opacity-100 scale-100"
        }`}
      >
        <Image
          src="/brand/zeroone-dark-icon.svg"
          alt="ZeroOne D.O.T.S AI"
          width={48}
          height={48}
          priority
        />
      </div>

      {/* Letter-by-letter text */}
      <div className="mt-5 h-10 overflow-hidden">
        <div className="flex items-center justify-center">
          {text.split("").map((char, i) => (
            <span
              key={i}
              className="inline-block font-[family-name:var(--font-display)] text-2xl md:text-3xl tracking-tight text-white transition-all duration-300"
              style={{
                opacity: i < visibleChars ? 1 : 0,
                transform: i < visibleChars ? "translateY(0)" : "translateY(20px)",
                transitionDelay: `${i * 12}ms`,
              }}
            >
              {char === " " ? "\u00A0" : char}
            </span>
          ))}
        </div>
      </div>

      {/* Tagline — appears during hold */}
      <p
        className={`mt-3 font-[family-name:var(--font-mono)] text-[10px] tracking-[0.22em] uppercase transition-all duration-500 delay-200 ${
          phase === "hold" || phase === "exit"
            ? "opacity-100 text-[rgba(215,207,240,0.5)]"
            : "opacity-0"
        }`}
      >
        D · O · T · S
      </p>
    </div>
  );
}
