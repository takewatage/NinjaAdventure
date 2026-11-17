import { fit, ease, seg, burst, sparkle, TAU, WHITE } from "../../core/index.js";
import { WATER, bead, ring } from "./_lib.js";

export const meta = {
  name: "Water charge full (top-down)",
  desc: "The moment a water charge is full, seen from above: a white flash at the hand, a ring bursting out round the body, glints and a spray of droplets. Plays once over the charge loop.",
  tags: ["water", "charge", "ready", "ninja", "magic", "top-down", "one-shot"],
  size: [72, 72],
  origin: [36, 36],          // = the character's center
  duration: 0.35,
  loop: false,
  fps: 30,
  bg: "dark",
  options: { palette: WATER, hand: [10, 0], seed: 3 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 8), [hx, hy] = o.hand;
  if (t < 0.08) {
    const f = 1 - t / 0.08;
    p.circle(hx, hy, 2 + 3 * f, WHITE);
    p.glow(hx, hy, 20, C[5], 0.8 * f);
  }
  const u = seg(t, 0, 0.3);
  if (u < 1) ring(p, 0, 0, 8 + 18 * ease.outCubic(u), 0.85, 1 - u, C, { n: 2, gap: 3, hot: u < 0.35, glint: 1, seed: 5 });
  burst(4, o.seed, (r, i) => {
    const a = i * TAU / 4 + 0.4, d = 15 + r.range(-2, 2), st = r.range(0.03, 0.1), life = 0.18, k = (t - st) / life;
    if (k < 0 || k > 1) return;
    sparkle(p, Math.cos(a) * d, Math.sin(a) * d * 0.85, 3 * Math.sin(Math.PI * k), C[6], WHITE, 0.6);
  });
  burst(12, o.seed + 1, (r) => {
    const a = r.range(0, TAU), sp = r.range(60, 110), life = r.range(0.15, 0.28), s = r.chance(0.3) ? 2 : 1;
    if (t > life) return;
    const d = 10 + sp * t * (1 - t * 1.5);
    bead(p, Math.cos(a) * d, Math.sin(a) * d * 0.85, Math.cos(a) * sp, Math.sin(a) * sp * 0.85, s, C, 1 - t / life);
  });
}
