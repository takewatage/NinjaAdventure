import { fit, clamp, smooth, ease, seg, rng, sparkle, TAU, WHITE } from "../../core/index.js";
import { drawLeaf } from "./_lib.js";

export const meta = {
  name: "Fuuton tornado (top-down)",
  desc: "The tornado a wind ball raises where it lands, top-down 3/4: a burst ring and a funnel winding up (spawn), spinning bands, leaves and dust (loop), unwinding away (end).",
  tags: ["wind", "tornado", "jutsu", "ninja", "aoe", "hazard", "magic", "top-down", "loop"],
  size: [72, 80],
  origin: [36, 68],          // = the tornado's foot on the ground (the landing point)
  duration: 0.8,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#2a4a52", "#5b9aa0", "#a6e0dc", "#e2fbf6", "#ffffff"],
    leaves: ["#123818", "#2f7a2a", "#6cb83a", "#c8f070"],
    dust: ["#4e3e2e", "#76624a", "#a08a6a", "#cbb894"],
    phase: "loop",           // "spawn" | "loop" | "end"
    height: 48,
    seed: 5,
  },
};

const D = meta.duration, SY = 0.36;

// the funnel's shape at height h (0 = ground .. 1 = top): radius flares upward, the axis sways (a wave running up)
const radiusAt = (u) => 5 + 13 * Math.pow(u, 1.25);
const swayAt = (u, t) => 2.2 * Math.sin(u * 3.2 - (t / D) * TAU) * u;

export function draw(p, t, o) {
  const C = fit(o.palette, 5), L = fit(o.leaves, 4), DU = fit(o.dust, 4), H = o.height, S = o.seed, ph = o.phase;
  // grow: how much of the funnel stands (spawn grows it, end takes it away from the bottom up), and its strength
  let grow = 1, fade = 1, tt = t;
  if (ph === "spawn") { grow = ease.outCubic(seg(t, 0.08, 0.5)); fade = Math.min(1, t / 0.15); }
  if (ph === "end") { grow = 1; fade = 1 - smooth(0, 0.55, t); }
  const lift = ph === "end" ? ease.inQuad(seg(t, 0, 0.55)) : 0;      // the bottom lets go and the funnel rises apart
  const spin = (tt / D) * TAU * 2;                                     // 2 turns per loop

  // ---- dust ring at the foot (under everything)
  const dk = (ph === "end" ? 1 - smooth(0, 0.35, t) : 1) * (ph === "spawn" ? smooth(0, 0.2, t) : 1);
  if (dk > 0.02) {
    for (let i = 0; i < 18; i++) {
      const a = spin * 0.8 + i / 18 * TAU, rr = 10 + 2 * Math.sin(i * 2.3 + spin);
      const x = Math.cos(a) * rr, y = Math.sin(a) * rr * SY;
      p.dot(x, y, i % 3 ? DU[2] : DU[3], 0.8 * dk);
      if (i % 2) p.dot(x - Math.sin(a) * 1.2, y + Math.cos(a) * 0.5, DU[1], 0.6 * dk);
    }
    for (let i = 0; i < 6; i++) {
      const r = rng(S + 70, i), a = spin * 0.6 + r.range(0, TAU), rr = r.range(8, 14);
      p.disc(Math.cos(a) * rr, Math.sin(a) * rr * SY - 1, r.range(1.2, 2.2), DU[2], 0.55 * dk);
    }
  }

  // ---- the funnel: bands of wind wound round it; back halves first, then debris behind, then front halves
  const bands = [];
  const STEP = 3.5;
  for (let h = 0; h <= H * grow; h += STEP) {
    const u = h / H, r = radiusAt(u), cx = swayAt(u, tt), y = -h - lift * 18;
    const bottomGone = ph === "end" ? h / H < lift * 1.1 : false;
    if (bottomGone) continue;
    const topK = 1 - smooth(0.85, 1, u) * 0.5;
    const nb = 2;
    for (let b = 0; b < nb; b++) {
      const a0 = spin + b * TAU / nb + u * 7 + (Math.round(h / STEP) % 2) * 1.3;   // bands twist up the funnel, alternate rows offset
      bands.push({ u, r, cx, y, a0, k: fade * topK });
    }
  }
  const arc = (q, front) => {
    const len = 1.9 + q.u * 0.5, n = Math.max(5, Math.round(q.r * len * 1.1));
    for (let i = 0; i <= n; i++) {
      const v = i / n, a = q.a0 - v * len, s = Math.sin(a);
      if ((s >= 0) !== front) continue;
      const x = q.cx + Math.cos(a) * q.r, y = q.y + s * q.r * SY;
      if (!front && v > 0.7) continue;
      const c = front ? (v < 0.15 ? C[4] : v < 0.5 ? C[3] : C[2]) : (v < 0.35 ? C[2] : C[1]);
      p.dot(x, y, c, q.k >= 0.98 ? 1 : q.k);
    }
  };
  // a soft light inside so it reads as a volume (light, not pixels)
  for (let h = 6; h <= H * grow; h += 10) if (!(ph === "end" && h / H < lift * 1.1)) p.glow(swayAt(h / H, tt), -h - lift * 18, radiusAt(h / H) * 0.8, C[2], 0.12 * fade);
  for (const q of bands) arc(q, false);

  // leaves and bits whirling up round it (front/back by angle)
  const leaves = [];
  for (let i = 0; i < 10; i++) {
    const r = rng(S + 30, i), base = r.next() * D, life = D * r.range(1, 1.6), turns = r.range(1.5, 2.5);
    for (let n = -2; n <= 0; n++) {
      const b = base + n * D, age = tt - b;
      if (age < 0 || age > life) continue;
      const v = age / life, u = v * grow * 0.95, a = r.range(0, TAU) + v * turns * TAU;
      const rr = radiusAt(u) + 2, x = swayAt(u, tt) + Math.cos(a) * rr, y = -u * H - lift * 18 + Math.sin(a) * rr * SY;
      leaves.push({ x, y, a, front: Math.sin(a) >= 0, k: fade * Math.min(1, v * 5) * (1 - smooth(0.8, 1, v)), green: i % 3 !== 0 });
    }
  }
  const leaf = (q) => q.green ? drawLeaf(p, q.x, q.y, 3.5, 1.3, q.a * 1.7, q.a * 2.5, L, q.k) : p.dot(q.x, q.y, DU[1], q.k);
  for (const q of leaves) if (!q.front) leaf(q);
  for (const q of bands) arc(q, true);
  for (const q of leaves) if (q.front) leaf(q);

  // ---- spawn: the landing burst
  if (ph === "spawn") {
    const u = seg(t, 0, 0.3);
    if (u < 1) {
      if (u < 0.2) { p.circle(0, -2, 4 * (1 - u * 3) + 1, WHITE); p.glow(0, -2, 16, C[3], 0.6 * (1 - u * 5)); }
      const rr = 4 + 16 * ease.outCubic(u);
      for (let i = 0; i < 28; i++) {
        const a = i / 28 * TAU + u * 2;
        p.dot(Math.cos(a) * rr, Math.sin(a) * rr * SY - 1, i % 2 ? C[3] : C[4], 1 - u);
      }
    }
  }
  // ---- end: wisps flung off as it unwinds
  if (ph === "end") {
    for (let i = 0; i < 5; i++) {
      const r = rng(S + 90, i), a = r.range(0, TAU), u = seg(t, r.range(0, 0.15), 0.5);
      if (u <= 0 || u >= 1) continue;
      const h = r.range(0.3, 0.9) * H, rr = radiusAt(h / H) + 18 * ease.outCubic(u);
      const x = Math.cos(a) * rr, y = -h - lift * 18 + Math.sin(a) * rr * SY;
      p.line(x, y, x - Math.sin(a) * 4, y + Math.cos(a) * 2, C[3], (1 - u) * 0.9);
    }
  }
}
