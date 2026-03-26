"use client";
import { useEffect, useRef } from "react";

/*
  WHITE Milky Way Galaxy — adapted from web.dotsai.cloud GalaxyBackground.tsx
  Key difference: uses WHITE/SILVER palette instead of dark D.O.T.S. colors
  - 1800 particles in 3-arm spiral galaxy
  - 8% big block stars with glow halos
  - Spring physics — particles return to home position
  - Hover distortion (120px radius)
  - Click physics kick + double ripple ring
  - Scroll fade (fades out past hero)
*/

const PALETTE = [
  { r: 255, g: 255, b: 255 },  // pure white
  { r: 215, g: 207, b: 240 },  // lavender-white
  { r: 201, g: 222, b: 255 },  // sky-white
  { r: 220, g: 240, b: 230 },  // mint-white
  { r: 255, g: 248, b: 235 },  // cream-white
];

interface Star {
  x: number; y: number;
  baseX: number; baseY: number;
  vx: number; vy: number;
  size: number;
  color: typeof PALETTE[0];
  brightness: number;
  phase: number;
  isBig: boolean;
  mass: number;
}

export default function GalaxyBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const mouseRef = useRef({ x: -9999, y: -9999 });
  const clickRef = useRef<{ x: number; y: number; time: number } | null>(null);
  const scrollRef = useRef(0);

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

    const count = isMobile ? 900 : 1800;
    const stars: Star[] = [];

    for (let i = 0; i < count; i++) {
      const angle  = (i / count) * Math.PI * 8;
      const radius = (i / count) * Math.max(W, H) * 0.85;
      const arm    = i % 3;
      const armOff = (arm / 3) * Math.PI * 2;

      const x = W / 2 + Math.cos(angle + armOff) * radius + (Math.random() - 0.5) * W * 0.3;
      const y = H / 2 + Math.sin(angle + armOff) * radius * 0.4 + (Math.random() - 0.5) * H * 0.4;

      const isBig = Math.random() < 0.08;
      const size  = isBig ? 2 + Math.random() * 3 : 0.4 + Math.random() * 1.2;
      const color = PALETTE[i % PALETTE.length];

      stars.push({
        x, y, baseX: x, baseY: y,
        vx: 0, vy: 0,
        size, color,
        brightness: 0.25 + Math.random() * 0.75,
        phase: Math.random() * Math.PI * 2,
        isBig,
        mass: isBig ? 3 + Math.random() * 2 : 0.5 + Math.random() * 0.5,
      });
    }

    const handleMouse = (e: MouseEvent) => {
      mouseRef.current = { x: e.clientX, y: e.clientY };
    };
    const handleClick = (e: MouseEvent) => {
      clickRef.current = { x: e.clientX, y: e.clientY, time: performance.now() };
      for (const s of stars) {
        const dx = s.x - e.clientX;
        const dy = s.y - e.clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 280 && dist > 0) {
          const angle = Math.atan2(dy, dx);
          const kick  = ((280 - dist) / 280) ** 2 * 14 / s.mass;
          s.vx += Math.cos(angle) * kick;
          s.vy += Math.sin(angle) * kick;
        }
      }
    };
    const handleScroll = () => { scrollRef.current = window.scrollY; };

    window.addEventListener("resize",    resize);
    window.addEventListener("mousemove", handleMouse, { passive: true });
    window.addEventListener("scroll",    handleScroll, { passive: true });
    window.addEventListener("click",     handleClick);

    let time = 0;
    let raf: number;

    function draw() {
      ctx!.clearRect(0, 0, W, H);
      time += 0.005;

      // Scroll fade — disappear as user scrolls past hero
      const scrollFade = Math.max(0, 1 - scrollRef.current / (H * 0.8));
      if (scrollFade <= 0) { raf = requestAnimationFrame(draw); return; }
      ctx!.globalAlpha = scrollFade;

      const mx = mouseRef.current.x;
      const my = mouseRef.current.y;

      for (const s of stars) {
        const dx   = s.x - mx;
        const dy   = s.y - my;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < 120 && dist > 0) {
          const angle = Math.atan2(dy, dx);
          const force = ((120 - dist) / 120) * 0.3;
          s.vx += Math.cos(angle) * force / s.mass;
          s.vy += Math.sin(angle) * force / s.mass;
        }

        s.vx += (s.baseX - s.x) * 0.003;
        s.vy += (s.baseY - s.y) * 0.003;
        s.vx *= 0.96;
        s.vy *= 0.96;
        s.x  += s.vx;
        s.y  += s.vy;

        s.phase += 0.01 + Math.random() * 0.004;
        const twinkle = 0.5 + 0.5 * Math.sin(time * 2 + s.phase);
        const alpha   = s.brightness * twinkle * 0.65;
        const { r, g, b } = s.color;

        if (s.isBig) {
          const gr = ctx!.createRadialGradient(s.x, s.y, 0, s.x, s.y, s.size * 5);
          gr.addColorStop(0, `rgba(${r},${g},${b},${(alpha * 0.25).toFixed(3)})`);
          gr.addColorStop(1, `rgba(${r},${g},${b},0)`);
          ctx!.fillStyle = gr;
          ctx!.beginPath();
          ctx!.arc(s.x, s.y, s.size * 5, 0, Math.PI * 2);
          ctx!.fill();
          ctx!.fillStyle = `rgba(${r},${g},${b},${alpha.toFixed(3)})`;
          ctx!.fillRect(s.x - s.size / 2, s.y - s.size / 2, s.size, s.size);
        } else {
          ctx!.fillStyle = `rgba(${r},${g},${b},${(alpha * 0.55).toFixed(3)})`;
          ctx!.beginPath();
          ctx!.arc(s.x, s.y, s.size, 0, Math.PI * 2);
          ctx!.fill();
        }
      }

      // Click ripple
      if (clickRef.current) {
        const age = (performance.now() - clickRef.current.time) / 1000;
        if (age < 0.7) {
          [300, 180].forEach((speed, i) => {
            const ripR = age * speed;
            const ripA = (1 - age / 0.7) * (i === 0 ? 0.15 : 0.09);
            ctx!.beginPath();
            ctx!.arc(clickRef.current!.x, clickRef.current!.y, ripR, 0, Math.PI * 2);
            ctx!.strokeStyle = `rgba(255,255,255,${ripA.toFixed(3)})`;
            ctx!.lineWidth = i === 0 ? 1.5 : 1;
            ctx!.stroke();
          });
        } else {
          clickRef.current = null;
        }
      }

      ctx!.globalAlpha = 1;
      raf = requestAnimationFrame(draw);
    }
    draw();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize",    resize);
      window.removeEventListener("mousemove", handleMouse);
      window.removeEventListener("scroll",    handleScroll);
      window.removeEventListener("click",     handleClick);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none"
      style={{ zIndex: 0 }}
      aria-hidden="true"
    />
  );
}
