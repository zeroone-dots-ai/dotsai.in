"use client";
import { useEffect, useRef } from "react";

/*
  DRAG-AND-DROP ∞ Infinity Companion — ported from web.dotsai.cloud
  Adapted for dotsai.in Paper/Plum color scheme:
  - Ghost path in plum (#43305F) instead of purple
  - Energy pulses in lavender/gold
  - Stays on right side during hero, moves left/right with sections
*/

const COLORS = [
  { r: 215, g: 207, b: 240 }, // lavender
  { r: 201, g: 222, b: 212 }, // mint
  { r: 178, g: 135, b: 67  }, // gold
  { r: 162, g: 210, b: 255 }, // sky
];

function infinityPoint(t: number, cx: number, cy: number, sx: number, sy: number) {
  const denom = 1 + Math.sin(t) * Math.sin(t);
  return {
    x: cx + (sx * Math.cos(t)) / denom,
    y: cy + (sy * Math.sin(t) * Math.cos(t)) / denom,
  };
}

interface Particle {
  x: number; y: number;
  vx: number; vy: number;
  radius: number;
  color: typeof COLORS[0];
  phase: number;
  speed: number;
  orbit: boolean;
  glow: number;
  alpha: number;
}

export default function InfinityCompanion() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef  = useRef({ x: -9999, y: -9999 });
  const scrollTarget = useRef({ x: 0.72, y: 0.50 });
  const currentPos   = useRef({ x: 0.72, y: 0.50 });
  const dragOffset   = useRef<{ x: number; y: number } | null>(null);
  const isDragging   = useRef(false);
  const dropPos      = useRef<{ x: number; y: number } | null>(null);
  const dropTime     = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let W = window.innerWidth;
    let H = window.innerHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const isMobile = W < 768;

    const resize = () => {
      W = window.innerWidth;
      H = window.innerHeight;
      canvas.width  = W * dpr;
      canvas.height = H * dpr;
      canvas.style.width  = `${W}px`;
      canvas.style.height = `${H}px`;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.scale(dpr, dpr);
    };
    resize();

    const baseScale = Math.min(W, H) * 0.16;
    const scaleX    = baseScale * 1.5;
    const scaleY    = baseScale * 0.75;

    const ORBIT_COUNT = isMobile ? 40 : 60;
    const FREE_COUNT  = isMobile ? 8  : 15;
    const particles: Particle[] = [];

    const initCx = W * 0.72;
    const initCy = H * 0.50;

    for (let i = 0; i < ORBIT_COUNT; i++) {
      const phase = (i / ORBIT_COUNT) * Math.PI * 2;
      const pt = infinityPoint(phase, initCx, initCy, scaleX, scaleY);
      particles.push({
        x: pt.x + (Math.random() - 0.5) * 14,
        y: pt.y + (Math.random() - 0.5) * 14,
        vx: 0, vy: 0,
        radius: 0.8 + Math.random() * 1.8,
        color: COLORS[i % 4],
        phase, speed: 0.0014 + Math.random() * 0.0018,
        orbit: true, glow: Math.random(), alpha: 0.65 + Math.random() * 0.35,
      });
    }
    for (let i = 0; i < FREE_COUNT; i++) {
      particles.push({
        x: initCx + (Math.random() - 0.5) * scaleX * 3,
        y: initCy + (Math.random() - 0.5) * scaleY * 3,
        vx: (Math.random() - 0.5) * 0.3, vy: (Math.random() - 0.5) * 0.3,
        radius: 0.4 + Math.random() * 0.8,
        color: COLORS[i % 4],
        phase: Math.random() * Math.PI * 2, speed: 0,
        orbit: false, glow: Math.random(), alpha: 0.08 + Math.random() * 0.07,
      });
    }

    const updateScrollTarget = () => {
      const sy = window.scrollY;
      const vh = H;
      if (sy < vh) {
        const p = sy / vh;
        scrollTarget.current = { x: 0.72 + p * 0.05, y: 0.48 };
      } else {
        const chapterH = vh * 0.9;
        const progress = sy - vh;
        const idx = Math.floor(progress / chapterH);
        scrollTarget.current = {
          x: idx % 2 === 0 ? 0.78 : 0.22,
          y: 0.48 + Math.sin(progress * 0.0006) * 0.04,
        };
      }
    };

    const isNear = (mx: number, my: number) => {
      const cx = W * currentPos.current.x;
      const cy = H * currentPos.current.y;
      return Math.hypot(mx - cx, my - cy) < scaleX * 1.3;
    };

    const onMouseDown = (e: MouseEvent) => {
      if (!isNear(e.clientX, e.clientY)) return;
      isDragging.current  = true;
      const cx = W * currentPos.current.x;
      const cy = H * currentPos.current.y;
      dragOffset.current  = { x: e.clientX - cx, y: e.clientY - cy };
      dropPos.current     = null;
      canvas.style.cursor = "grabbing";
    };
    const onMouseMove = (e: MouseEvent) => {
      mouseRef.current = { x: e.clientX, y: e.clientY };
      if (isDragging.current && dragOffset.current) {
        currentPos.current = {
          x: (e.clientX - dragOffset.current.x) / W,
          y: (e.clientY - dragOffset.current.y) / H,
        };
      } else {
        canvas.style.cursor = isNear(e.clientX, e.clientY) ? "grab" : "default";
      }
    };
    const onMouseUp = () => {
      if (!isDragging.current) return;
      isDragging.current  = false;
      dragOffset.current  = null;
      dropPos.current     = { ...currentPos.current };
      dropTime.current    = performance.now();
      canvas.style.cursor = "grab";
    };

    canvas.addEventListener("mousedown", onMouseDown);
    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup",   onMouseUp);
    window.addEventListener("resize",    resize);
    window.addEventListener("scroll",    updateScrollTarget, { passive: true });
    updateScrollTarget();
    currentPos.current = { ...scrollTarget.current };

    let time = 0, raf: number;

    function draw() {
      ctx!.clearRect(0, 0, W, H);
      time += 0.007;

      if (!isDragging.current) {
        if (dropPos.current) {
          const elapsed = (performance.now() - dropTime.current) / 1000;
          if (elapsed < 3) {
            const t = Math.min(elapsed / 3, 1);
            const ease = t * t * (3 - 2 * t);
            const target = {
              x: dropPos.current.x + (scrollTarget.current.x - dropPos.current.x) * ease,
              y: dropPos.current.y + (scrollTarget.current.y - dropPos.current.y) * ease,
            };
            currentPos.current.x += (target.x - currentPos.current.x) * 0.06;
            currentPos.current.y += (target.y - currentPos.current.y) * 0.06;
          } else { dropPos.current = null; }
        } else {
          currentPos.current.x += (scrollTarget.current.x - currentPos.current.x) * 0.025;
          currentPos.current.y += (scrollTarget.current.y - currentPos.current.y) * 0.025;
        }
      }

      const cx = W * currentPos.current.x;
      const cy = H * currentPos.current.y;

      // Ghost path — plum color
      for (let s = 0; s < 200; s++) {
        const t0 = (s / 200) * Math.PI * 2;
        const t1 = ((s + 1) / 200) * Math.PI * 2;
        const p0 = infinityPoint(t0, cx, cy, scaleX, scaleY);
        const p1 = infinityPoint(t1, cx, cy, scaleX, scaleY);
        const a  = 0.05 + 0.03 * Math.sin(t0 * 2 + time);
        ctx!.beginPath();
        ctx!.moveTo(p0.x, p0.y);
        ctx!.lineTo(p1.x, p1.y);
        ctx!.strokeStyle = `rgba(67,48,95,${a})`;
        ctx!.lineWidth = 1;
        ctx!.stroke();
      }

      // Energy pulse — lavender leading, gold trailing
      const pulseT = (time * 0.8) % (Math.PI * 2);
      const pp = infinityPoint(pulseT, cx, cy, scaleX, scaleY);
      const g1 = ctx!.createRadialGradient(pp.x, pp.y, 0, pp.x, pp.y, 16);
      g1.addColorStop(0, "rgba(215,207,240,0.60)");
      g1.addColorStop(0.4, "rgba(67,48,95,0.20)");
      g1.addColorStop(1, "rgba(67,48,95,0)");
      ctx!.beginPath(); ctx!.arc(pp.x, pp.y, 16, 0, Math.PI * 2);
      ctx!.fillStyle = g1; ctx!.fill();
      ctx!.beginPath(); ctx!.arc(pp.x, pp.y, 3, 0, Math.PI * 2);
      ctx!.fillStyle = "rgba(235,225,255,0.95)"; ctx!.fill();

      const pp2 = infinityPoint((pulseT + Math.PI) % (Math.PI * 2), cx, cy, scaleX, scaleY);
      ctx!.beginPath(); ctx!.arc(pp2.x, pp2.y, 2.5, 0, Math.PI * 2);
      ctx!.fillStyle = "rgba(178,135,67,0.80)"; ctx!.fill();

      // Particles
      const mx = mouseRef.current.x;
      const my = mouseRef.current.y;

      for (const p of particles) {
        if (p.orbit) {
          p.phase += p.speed;
          const target = infinityPoint(p.phase, cx, cy, scaleX, scaleY);
          p.vx += (target.x - p.x) * 0.014;
          p.vy += (target.y - p.y) * 0.014;
          p.vx *= 0.90; p.vy *= 0.90;
        } else {
          p.vx += Math.sin(time * 0.9 + p.phase) * 0.003;
          p.vy += Math.cos(time * 0.7 + p.phase) * 0.003;
          p.vx *= 0.994; p.vy *= 0.994;
        }

        if (!isDragging.current) {
          const dist = Math.hypot(p.x - mx, p.y - my);
          if (dist < 130 && dist > 0) {
            const angle = Math.atan2(p.y - my, p.x - mx);
            const force = (130 - dist) / 130;
            p.vx -= Math.cos(angle) * force * 0.10;
            p.vy -= Math.sin(angle) * force * 0.10;
          }
        }

        p.x += p.vx; p.y += p.vy;
        p.glow = 0.5 + 0.5 * Math.sin(time * 2.2 + p.phase);
        const alpha = p.orbit ? (0.55 + p.glow * 0.45) * p.alpha : p.alpha * (0.6 + p.glow * 0.4);

        if (p.orbit && p.glow > 0.45) {
          const gr = ctx!.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.radius * 5);
          gr.addColorStop(0, `rgba(${p.color.r},${p.color.g},${p.color.b},${(alpha * 0.28).toFixed(3)})`);
          gr.addColorStop(1, `rgba(${p.color.r},${p.color.g},${p.color.b},0)`);
          ctx!.fillStyle = gr;
          ctx!.beginPath(); ctx!.arc(p.x, p.y, p.radius * 5, 0, Math.PI * 2); ctx!.fill();
        }
        ctx!.fillStyle = `rgba(${p.color.r},${p.color.g},${p.color.b},${alpha.toFixed(3)})`;
        ctx!.beginPath(); ctx!.arc(p.x, p.y, p.radius, 0, Math.PI * 2); ctx!.fill();
      }

      // Connection lines
      const orbitP = particles.filter((p) => p.orbit);
      for (let i = 0; i < orbitP.length; i++) {
        for (let j = i + 1; j < orbitP.length; j++) {
          const d = Math.hypot(orbitP[i].x - orbitP[j].x, orbitP[i].y - orbitP[j].y);
          if (d < 100) {
            const a = 0.06 * (1 - d / 100);
            const c = orbitP[i].color;
            ctx!.beginPath();
            ctx!.moveTo(orbitP[i].x, orbitP[i].y);
            ctx!.lineTo(orbitP[j].x, orbitP[j].y);
            ctx!.strokeStyle = `rgba(${c.r},${c.g},${c.b},${a})`;
            ctx!.lineWidth = 0.5; ctx!.stroke();
          }
        }
      }

      raf = requestAnimationFrame(draw);
    }
    draw();

    return () => {
      cancelAnimationFrame(raf);
      canvas.removeEventListener("mousedown", onMouseDown);
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup",   onMouseUp);
      window.removeEventListener("resize",    resize);
      window.removeEventListener("scroll",    updateScrollTarget);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0"
      style={{ zIndex: 1, pointerEvents: "auto", cursor: "grab" }}
      aria-hidden="true"
    />
  );
}
