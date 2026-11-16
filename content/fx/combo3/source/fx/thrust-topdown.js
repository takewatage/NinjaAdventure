import { fit, sparkle, clamp, smooth, ease, seg, burst, fly, flyV, WHITE } from "../../core/index.js";

export const meta = {
  name: "Thrust (top-down)",
  desc: "A quick forward stab seen from above: a white lance streak shoots out two tiles with speed lines, pops a small ring at the tip and pulls back.",
  tags: ["melee", "thrust", "stab", "sword", "top-down", "simple", "one-shot"],
  size: [96, 96],
  origin: [48, 48],          // = the character's center
  duration: 0.4,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#4a5f8a", "#7f98c4", "#b4cbec", "#e2efff", "#ffffff"],
    facing: Math.PI / 2,     // PI/2 = south (down), 0 = east, PI = west, -PI/2 = north
    reach: 38,               // how far the tip goes from the character center (px)
    seed: 9,
  },
};

const OUT = 0.06;            // time to reach full length
const SY = 0.9;

export function draw(p, t, o) {
  const C = fit(o.palette, 5), L = o.reach;
  const fx = Math.cos(o.facing), fy = Math.sin(o.facing) * SY;   // forward on screen
  const nx = -Math.sin(o.facing), ny = Math.cos(o.facing) * SY;  // sideways on screen
  const P = (s, n) => [fx * s + nx * n, fy * s + ny * n];

  const ext = ease.outExpo(clamp(t / OUT));
  const tip = 6 + (L - 6) * ext;
  const base = 6 + (L - 10) * smooth(OUT, 0.24, t);             // the tail catches up with the tip
  const age = seg(t, 0, 0.26);

  // the lance streak: white core, cooling edges, sharp tip
  if (tip - base > 1) {
    const B = L + 4;
    p.shade(-B, -B, B, B, (x, y, out) => {
      // back into (s, n) along the facing direction (undo the squash first)
      const X = x, Y = y / SY, c = Math.cos(o.facing), s_ = Math.sin(o.facing);
      const s = X * c + Y * s_, n = -X * s_ + Y * c;
      if (s < base || s > tip) return;
      const v = (s - base) / Math.max(1, tip - base);           // 0 at the tail, 1 at the tip
      const w = 4.6 * Math.pow(Math.min(1, (1 - v) / 0.35), 0.8) * (0.4 + 0.6 * v);
      const q = Math.abs(n) / Math.max(0.01, w);
      if (q > 1) return;
      const ci = q < 0.35 && age < 0.6 ? 0 : Math.round(q * 2 + (1 - v) * 1.5 + age * 2.5);
      out.c = C[4 - clamp(ci, 0, 4)];
      out.a = 1 - smooth(0.7, 1, age);
    });
    const [gx, gy] = P(tip - 2, 0);
    p.glow(gx, gy, 10, C[3], 0.45 * (1 - age));
  }

  // speed lines either side
  burst(4, o.seed, (r, i) => {
    const side = i % 2 ? 1 : -1, off = side * r.range(5, 8), t0 = r.range(0.01, 0.05), life = r.range(0.1, 0.16);
    const u = t - t0;
    if (u < 0 || u > life) return;
    const k = u / life, s1 = 8 + (L - 4) * ease.outCubic(k), s0 = s1 - r.range(6, 10) * (1 - k);
    const [x0, y0] = P(s0, off), [x1, y1] = P(s1, off);
    p.line(x0, y0, x1, y1, (v) => (v > 0.6 ? C[4] : C[2]), 1 - k);
  });

  // pop at the tip: a small flat ring across the thrust, plus sparks
  const pu = seg(t, OUT * 0.8, OUT + 0.16);
  if (pu > 0 && pu < 1) {
    const rr = 3 + 8 * ease.outCubic(pu), [cx, cy] = P(L, 0);
    for (let a = 0; a < Math.PI * 2; a += 0.25) {
      const [x, y] = [cx + nx * Math.cos(a) * rr + fx * Math.sin(a) * rr * 0.35, cy + ny * Math.cos(a) * rr + fy * Math.sin(a) * rr * 0.35];
      p.dot(x, y, pu < 0.4 ? C[4] : C[3], 1 - pu);
    }
  }
  if (t > OUT * 0.8 && t < OUT + 0.06) {
    const [x, y] = P(L, 0);
    sparkle(p, x, y, 3, C[3], WHITE, 0.6);
  }
  burst(5, o.seed + 3, (r) => {
    const life = r.range(0.1, 0.2), u = t - OUT * 0.8, spread = r.range(-0.9, 0.9), sp = r.range(50, 90);
    if (u < 0 || u > life) return;
    const a = o.facing + spread, [sx, sy] = P(L, 0);
    const vx = Math.cos(a) * sp, vy = Math.sin(a) * sp * SY;
    const [x, y] = fly(sx, sy, vx, vy, u, 0, 8), [ux, uy] = flyV(vx, vy, u, 0, 8);
    p.line(x - ux * 0.03, y - uy * 0.03, x, y, (v) => (v > 0.6 ? WHITE : C[3]), 1 - u / life);
  });
}
