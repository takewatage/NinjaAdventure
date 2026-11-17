import { fit, clamp, ease, seg, burst, sparkle, WHITE, TAU } from "../../core/index.js";
import { WATER, bead, ring } from "./_lib.js";

export const meta = {
  name: "Water shuriken cast (top-down)",
  desc: "Water gathers for a water shuriken thrown right: droplets spiral into the hand into a whirling ring, it flashes and bursts forward in a spray as the star leaves.",
  tags: ["water", "shuriken", "cast", "ninja", "magic", "muzzle", "top-down", "directional", "one-shot"],
  size: [56, 48],
  origin: [24, 24],          // = the character's center
  duration: 0.4,
  loop: false,
  fps: 30,
  bg: "dark",
  options: { palette: WATER, hand: [10, 0], release: 0.18, seed: 5 },
};

export function draw(p, t, o) {
  const C = fit(o.palette, 8), [px, py] = o.hand, T = o.release;
  if (t < T) {
    const k = t / T;
    // droplets spiralling in
    burst(10, o.seed, (r) => {
      const a0 = r.range(0, TAU), r0 = r.range(9, 15), st = r.range(0, 0.05), s = r.chance(0.3) ? 2 : 1;
      const u = clamp((t - st) / (T - st));
      if (u <= 0 || u >= 1) return;
      const a = a0 + 2.6 * u, rr = r0 * (1 - ease.inQuad(u)) + 2;
      const x = px + Math.cos(a) * rr, y = py + Math.sin(a) * rr * 0.9;
      bead(p, x, y, -Math.sin(a) * 80, Math.cos(a) * 80, s, C);
    });
    // a whirling ring tightening round the hand
    const rr = 6 - 3 * k;
    for (let i = 0; i < 10; i++) {
      const a = i / 10 * TAU + t * 30;
      if (i % 3 === 0) continue;
      p.dot(px + Math.cos(a) * rr, py + Math.sin(a) * rr * 0.9, i % 2 ? C[5] : C[4], 0.4 + 0.6 * k);
    }
    p.glow(px, py, 4 + 6 * k, C[4], 0.2 + 0.3 * k);
  }
  const u = seg(t, T, T + 0.22);
  if (u > 0 && u < 1) {
    if (u < 0.25) { p.circle(px, py, 3 * (1 - u * 3) + 1, WHITE); p.glow(px, py, 14, C[5], 0.6 * (1 - u * 4)); }
    ring(p, px + 2, py, 2 + 6 * ease.outCubic(u), 0.9, 1 - u, C, { n: 1, hot: u < 0.3, seed: 3 });
    burst(9, o.seed + 4, (r) => {
      const a = r.range(-0.8, 0.8), sp = r.range(60, 120), life = r.range(0.12, 0.2), s = r.chance(0.3) ? 2 : 1;
      const tt = t - T;
      if (tt > life) return;
      const d = sp * tt * (1 - tt * 2), vx = Math.cos(a) * sp, vy = Math.sin(a) * sp;
      bead(p, px + Math.cos(a) * d, py + Math.sin(a) * d * 0.9, vx, vy, s, C, 1 - tt / life);
    });
  }
}
