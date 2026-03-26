"use client";
import { useEffect, useState } from "react";
import Image from "next/image";

const NAV_LINKS = [
  { label: "Services", href: "#services" },
  { label: "Proof",    href: "#proof"    },
  { label: "Contact",  href: "#contact"  },
];

export default function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <>
      <nav
        className={`animate-slide-down fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled
            ? "bg-[#06060a]/85 backdrop-blur-xl border-b border-white/[0.05]"
            : "bg-transparent"
        }`}
      >
        <div className="mx-auto max-w-6xl px-6 h-[68px] flex items-center justify-between">
          <a href="#" className="flex items-center gap-3 group">
            <Image
              src="/brand/zeroone-dark-icon.svg"
              alt="ZeroOne D.O.T.S AI"
              width={28} height={28} priority
              className="group-hover:opacity-80 transition-opacity"
            />
            <span className="hidden sm:block text-[11px] font-[family-name:var(--font-mono)] tracking-[0.18em] uppercase text-white/70 group-hover:text-white transition-colors">
              ZEROONE D.O.T.S AI
            </span>
          </a>

          <div className="hidden md:flex items-center gap-8">
            {NAV_LINKS.map((l) => (
              <a
                key={l.href} href={l.href}
                className="text-sm text-white/45 hover:text-white transition-colors duration-200 tracking-wide"
              >
                {l.label}
              </a>
            ))}
          </div>

          <div className="flex items-center gap-3">
            <a
              href="https://wa.me/918320065658"
              target="_blank" rel="noopener"
              className={`hidden sm:inline-flex items-center px-4 py-2 rounded-full text-xs font-medium tracking-wide transition-all duration-200 ${
                scrolled
                  ? "bg-[#D7CFF0] text-[#171722] hover:brightness-110"
                  : "bg-white/[0.07] text-white hover:bg-white/[0.12] border border-white/[0.1]"
              }`}
            >
              ↗ Let&apos;s Talk
            </a>
            <button
              onClick={() => setOpen(!open)}
              className="md:hidden p-2 text-white/50 hover:text-white"
              aria-label="Menu"
            >
              <span className="block w-5 h-px bg-current mb-1.5 transition-all" />
              <span className="block w-3 h-px bg-current ml-auto" />
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile menu */}
      {open && (
        <div className="animate-fade-in fixed inset-0 z-40 bg-[#06060a]/96 backdrop-blur-xl flex flex-col items-center justify-center gap-10">
          <button onClick={() => setOpen(false)} className="absolute top-6 right-6 text-white/50 hover:text-white text-2xl">×</button>
          {NAV_LINKS.map((l) => (
            <a
              key={l.href} href={l.href}
              onClick={() => setOpen(false)}
              className="font-[family-name:var(--font-display)] text-3xl text-white"
            >
              {l.label}
            </a>
          ))}
          <a
            href="https://wa.me/918320065658"
            target="_blank" rel="noopener"
            className="px-8 py-3 rounded-full bg-[#D7CFF0] text-[#171722] font-medium"
          >
            ↗ Let&apos;s Talk
          </a>
        </div>
      )}
    </>
  );
}
