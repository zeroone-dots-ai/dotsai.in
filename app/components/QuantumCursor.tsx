"use client";
import { useEffect, useRef } from "react";

/*
  Quantum Field Cursor
  - Dot: instant 6px lavender glow
  - Ring: 44px spring-lagged circle
  - Trail: 28 comet particles in D.O.T.S. palette
  - Hover: ring expands, dot brightens (magnetic)
  - Click: ring shrinks + 14-particle burst
*/

const PALETTE: [number, number, number][] = [
  [215, 207, 240], // lavender
  [201, 222, 212], // mint
  [241, 198, 174], // peach
  [162, 210, 255], // sky
  [255, 181, 194], // rose
];

export default function QuantumCursor() {
  const dotRef   = useRef<HTMLDivElement>(null);
  const ringRef  = useRef<HTMLDivElement>(null);
  const trailRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;
    if (window.matchMedia("(pointer: coarse)").matches) return;

    const dot   = dotRef.current!;
    const ring  = ringRef.current!;
    const tc    = trailRef.current!;
    const ctx   = tc.getContext("2d")!;

    const TRAIL = 28;
    const hist: { x: number; y: number }[] = [];
    let mx = -999, my = -999;
    let rx = -999, ry = -999;
    let bursts: { t: number; ps: { x: number; y: number; vx: number; vy: number; color: [number,number,number]; size: number }[] }[] = [];

    const resize = () => {
      tc.width  = window.innerWidth;
      tc.height = window.innerHeight;
    };
    resize();
    window.addEventListener("resize", resize);

    const onMove = (e: MouseEvent) => {
      mx = e.clientX; my = e.clientY;
      dot.style.left = mx + "px";
      dot.style.top  = my + "px";
      hist.unshift({ x: mx, y: my });
      if (hist.length > TRAIL) hist.pop();
    };

    const onOver = (e: MouseEvent) => {
      if ((e.target as Element)?.closest("a,button,[role='button'],.magnetic")) {
        dot.classList.add("hovering");
        ring.classList.add("hovering");
      }
    };
    const onOut = (e: MouseEvent) => {
      if ((e.target as Element)?.closest("a,button,[role='button'],.magnetic")) {
        dot.classList.remove("hovering");
        ring.classList.remove("hovering");
      }
    };
    const onDown = () => {
      dot.classList.add("clicking");
      ring.classList.add("clicking");
      const ps = Array.from({ length: 14 }, (_, i) => {
        const a  = (i / 14) * Math.PI * 2 + Math.random() * 0.4;
        const sp = 1.5 + Math.random() * 5;
        return { x: mx, y: my, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
                 color: PALETTE[i % PALETTE.length], size: 1.5 + Math.random() * 2.5 };
      });
      bursts.push({ t: performance.now(), ps });
    };
    const onUp = () => {
      dot.classList.remove("clicking");
      ring.classList.remove("clicking");
    };

    document.addEventListener("mousemove", onMove, { passive: true });
    document.addEventListener("mouseover", onOver);
    document.addEventListener("mouseout",  onOut);
    document.addEventListener("mousedown", onDown);
    document.addEventListener("mouseup",   onUp);

    let raf: number;
    function draw() {
      ctx.clearRect(0, 0, tc.width, tc.height);

      // Spring ring
      rx += (mx - rx) * 0.10;
      ry += (my - ry) * 0.10;
      ring.style.left = rx + "px";
      ring.style.top  = ry + "px";

      // Comet trail
      for (let i = 0; i < hist.length; i++) {
        const p   = hist[i];
        const t   = i / TRAIL;
        const alp = (1 - t) * 0.52;
        const sz  = (1 - t) * 5;
        if (sz < 0.2 || alp < 0.01) continue;
        const ci  = Math.floor(i * PALETTE.length / TRAIL) % PALETTE.length;
        const c   = PALETTE[ci];
        const g   = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, sz * 2.5);
        g.addColorStop(0, `rgba(${c[0]},${c[1]},${c[2]},${alp.toFixed(3)})`);
        g.addColorStop(1, `rgba(${c[0]},${c[1]},${c[2]},0)`);
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(p.x, p.y, sz * 2.5, 0, Math.PI * 2); ctx.fill();
      }

      // Click bursts
      const now = performance.now();
      bursts = bursts.filter((b) => {
        const age = (now - b.t) / 800;
        if (age > 1) return false;
        for (const p of b.ps) {
          p.x += p.vx; p.y += p.vy;
          p.vx *= 0.91; p.vy *= 0.91;
          const al = (1 - age) * 0.85;
          const c  = p.color;
          ctx.fillStyle = `rgba(${c[0]},${c[1]},${c[2]},${al.toFixed(3)})`;
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size * (1 - age * 0.6), 0, Math.PI * 2); ctx.fill();
        }
        return true;
      });

      raf = requestAnimationFrame(draw);
    }
    draw();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      document.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseover", onOver);
      document.removeEventListener("mouseout",  onOut);
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("mouseup",   onUp);
    };
  }, []);

  return (
    <>
      <style>{`
        @media (pointer: fine) {
          *, *::before, *::after { cursor: none !important; }
        }
        #qc-dot {
          position: fixed; z-index: 99999; pointer-events: none;
          width: 6px; height: 6px; border-radius: 50%;
          background: rgb(215,207,240);
          box-shadow: 0 0 8px rgba(215,207,240,0.95), 0 0 24px rgba(215,207,240,0.5);
          mix-blend-mode: screen;
          transform: translate(-50%,-50%);
          left: -999px; top: -999px;
          transition: width .15s, height .15s, background .2s;
        }
        #qc-dot.hovering  { width:10px; height:10px; background:rgb(255,255,255); box-shadow:0 0 12px rgba(255,255,255,.9),0 0 30px rgba(215,207,240,.6); }
        #qc-dot.clicking  { width:4px;  height:4px;  background:rgb(255,255,255); }
        #qc-ring {
          position: fixed; z-index: 99998; pointer-events: none;
          width: 44px; height: 44px; border-radius: 50%;
          border: 1.5px solid rgba(215,207,240,0.35);
          transform: translate(-50%,-50%);
          left: -999px; top: -999px;
          transition: width .35s cubic-bezier(.22,.68,0,1.2), height .35s cubic-bezier(.22,.68,0,1.2), border-color .25s, box-shadow .25s;
        }
        #qc-ring.hovering { width:68px; height:68px; border-color:rgba(215,207,240,.75); box-shadow:0 0 18px rgba(215,207,240,.15),inset 0 0 16px rgba(215,207,240,.06); }
        #qc-ring.clicking { width:22px; height:22px; border-color:rgba(255,255,255,.95); box-shadow:0 0 28px rgba(255,255,255,.45); transition: width .08s,height .08s,border-color .08s,box-shadow .08s; }
        #qc-trail { position:fixed; inset:0; width:100vw; height:100vh; pointer-events:none; z-index:99997; }
      `}</style>
      <canvas id="qc-trail" ref={trailRef} aria-hidden="true" />
      <div    id="qc-dot"   ref={dotRef}   aria-hidden="true" />
      <div    id="qc-ring"  ref={ringRef}  aria-hidden="true" />
    </>
  );
}
