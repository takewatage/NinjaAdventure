// Crescent shading idea follows the sword slash in this repo (adapted from Sprite Fusion's open-source slash,
// https://www.spritefusion.com/pixel-art-vfx/slash, MIT License, Copyright (c) 2026 Hugo Duprez).
import { fit, sparkle, clamp, smooth, ease, seg, burst, fly, flyV, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Front slash (top-down)",
  desc: "A plain early-game sword sweep seen from above: a thin crescent cuts across the three tiles in front, flashes white and cools away, with a few tip sparks.",
  tags: ["melee", "slash", "sword", "top-down", "simple", "one-shot"],
  size: [96, 96],
  origin: [48, 48],          // = the character's center
  duration: 0.35,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#4a5f8a", "#7f98c4", "#b4cbec", "#e2efff", "#ffffff"],
    facing: Math.PI / 2,     // direction faced: PI/2 = south (down), 0 = east, PI = west, -PI/2 = north
    reach: 24,               // arc radius in px (16 px tiles: covers the 3 tiles in front)
    start: 0.0,              // when the swing begins (s)
    mirror: false,           // true: swing the other way (left -> right when facing south), for combo hit 2
    seed: 5,
  },
};

const SPAN = 2.3;            // arc width in radians (~150 deg): front-left, front, front-right
const SWEEP = 0.07;          // the swing itself is fast
const SY = 0.9;              // slight 3/4 squash

export function draw(p, t, o) {
  const C = fit(o.palette, 5), n = C.length, R = o.reach;
  const t0 = o.start, tt = t - t0;
  if (tt < 0) return;
  // sweep from the character's right-front to left-front (south: screen right -> left)
  const d = o.mirror ? -1 : 1;
  const aStart = o.facing - d * SPAN / 2, head = aStart + d * SPAN * ease.outQuart(clamp(tt / SWEEP));
  const toScreen = (r, a) => [Math.cos(a) * r, Math.sin(a) * r * SY];

  const age = seg(tt, 0, 0.3);
  const fade = smooth(SWEEP * 0.8, 0.3, tt);          // the tail creeps in a little...
  const thin = 1 - smooth(SWEEP * 0.6, 0.3, tt);      // ...while the whole crescent thins to a hairline and vanishes
  const len = Math.abs(head - aStart) * (1 - 0.45 * fade);
  if (len > 0.04) {
    const W = 6, B = R + 2;
    p.shade(-B, -B, B, B, (x, y, out) => {
      const ly = y / SY, r = Math.hypot(x, ly);
      if (r > R + 0.5 || r < R - W - 1) return;
      let u = (d * (head - Math.atan2(ly, x))) % TAU;
      if (u < 0) u += TAU;
      if (u > len) return;
      const v = u / len;
      // pointed at both ends: the leading tip tapers over ~0.55 rad, the tail over its whole length
      const w = W * thin * Math.pow(Math.min(1, u / 0.55), 0.7) * Math.pow(1 - v, 0.8);
      if (w < 0.35) return;
      const q = (R - r) / w;
      if (q < 0 || q > 1) return;
      const ci = q < 0.25 && v < 0.3 && age < 0.5 ? 0 : Math.round(q * (n - 1) * 0.6 + v * (n - 1) * 0.8 + age * 2);
      out.c = C[n - 1 - clamp(ci, 0, n - 1)];
      out.a = 1 - smooth(0.6, 1, v);
    });
    for (let u = 0; u < len; u += 0.4) {
      const [x, y] = toScreen(R - 2, head - d * u);
      p.glow(x, y, 5, C[3], 0.18 * (1 - u / len) * (1 - age));
    }
  }

  // blade glint at the tip while swinging
  if (tt < SWEEP + 0.03) {
    const [x, y] = toScreen(R - 1, head);
    sparkle(p, x, y, 2, C[3], WHITE, 0.5);
  }

  // a few small sparks thrown forward off the tip
  burst(5, o.seed, (r) => {
    const frac = r.range(0.3, 1), life = r.range(0.12, 0.22), sp = r.range(60, 100), da = r.range(-0.3, 0.3);
    const u = tt - SWEEP * frac;
    if (u < 0 || u > life) return;
    const a = aStart + d * SPAN * frac, [sx, sy] = toScreen(R - 1, a);
    const vx = Math.cos(a + da) * sp, vy = Math.sin(a + da) * sp * SY;
    const [x, y] = fly(sx, sy, vx, vy, u, 0, 8), [ux, uy] = flyV(vx, vy, u, 0, 8);
    const k = 1 - u / life;
    p.line(x - ux * 0.03, y - uy * 0.03, x, y, (v) => (v > 0.6 ? WHITE : C[3]), k);
  });
}
