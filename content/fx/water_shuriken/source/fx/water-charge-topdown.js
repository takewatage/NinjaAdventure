// Droplets use this folder's bead() (adapted from Sprite Fusion's open-source blood, MIT, Copyright (c) 2026 Hugo Duprez).
import { fit, clamp, ease, TAU, WHITE, rng } from "../../core/index.js";
import { WATER, bead, ring } from "./_lib.js";
import { star } from "./water-shuriken-topdown.js";

export const meta = {
  name: "Water charge (top-down)",
  desc: "Charging a big water shuriken, seen from above: water streams orbit the body, droplets spiral in, ripples spread at the feet and a star whirls in the hand. Loops.",
  tags: ["water", "charge", "shuriken", "ninja", "magic", "aura", "top-down", "loop"],
  size: [64, 64],
  origin: [32, 32],          // = the character's center
  duration: 0.6,
  loop: true,
  fps: 30,
  bg: "dark",
  options: { palette: WATER, hand: [10, 0], orbit: 13, seed: 4 },
};

const D = meta.duration, SY = 0.85;

export function draw(p, t, o) {
  const C = fit(o.palette, 8), [hx, hy] = o.hand, R = o.orbit, ph = t / D;
  // ripples at the feet (two per loop, seamless)
  for (let j = 0; j < 2; j++) {
    const u = (ph + j / 2) % 1;
    ring(p, 0, 8, 4 + 12 * ease.outCubic(u), 0.4, (1 - u) * 0.5, C, { n: 1, seed: j });
  }
  // droplets spiralling in towards the hand
  for (let i = 0; i < 12; i++) {
    const r = rng(o.seed, i), born = r.next() * D, life = r.range(0.25, 0.4), a0 = r.range(0, TAU), r0 = r.range(16, 24), s = r.chance(0.3) ? 2 : 1;
    for (let age = ((t - born) % D + D) % D; age < life; age += D) {
      const u = age / life, a = a0 + 3 * u, rr = r0 * (1 - ease.inQuad(u)) + 2;
      const x = hx * u + Math.cos(a) * rr, y = hy * u + Math.sin(a) * rr * SY;
      bead(p, x, y, -Math.sin(a) * 90, Math.cos(a) * 90 * SY, s, C, Math.min(1, u * 4));
    }
  }
  // three streams orbiting the body: one full turn per loop
  for (let k = 0; k < 3; k++) {
    const head = ph * TAU + k * TAU / 3;
    for (let i = 0; i < 16; i++) {
      const a = head - i * 0.1, w = 1 - i / 16, rr = R + Math.sin(a * 2 + k) * 1.2;
      const x = Math.cos(a) * rr, y = Math.sin(a) * rr * SY;
      p.dot(x, y, i < 2 ? WHITE : i < 6 ? C[6] : C[5], w);
      if (i < 9) p.dot(x, y + 1, i < 4 ? C[5] : C[4], 0.85 * w);
    }
  }
  // the star forming in the hand
  p.glow(hx, hy, 9, C[4], 0.35);
  star({
    shade: (x0, y0, x1, y1, f) => p.shade(x0 + hx, y0 + hy, x1 + hx, y1 + hy, (x, y, out) => f(x - hx, y - hy, out)),
    dot: (x, y, c, a) => p.dot(x + hx, y + hy, c, a),
  }, C, 4.5, ph * TAU * 2);
}
