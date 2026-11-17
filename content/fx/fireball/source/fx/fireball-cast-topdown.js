import { fit, mix, clamp, smooth, ease, seg, burst, sparkle, WHITE, TAU } from "../../core/index.js";
import { hotFirst, firePuff } from "./_lib.js";

export const meta = {
  name: "Fireball cast (top-down)",
  desc: "The spark before a small fireball, cast to the right: embers swirl into a point in front of the hand, it flares white and bursts into a puff of flame that the fireball leaves from.",
  tags: ["fire", "fireball", "cast", "magic", "muzzle", "top-down", "directional", "one-shot"],
  size: [56, 48],
  origin: [24, 24],          // = the character's center
  duration: 0.4,
  loop: false,
  fps: 30,
  bg: "dark",
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    hand: [10, 0],           // where the fireball appears, from the character's center (facing right)
    release: 0.2,            // the moment the fireball leaves (s)
    seed: 6,
  },
};

export function draw(p, t, o) {
  const H = hotFirst(fit(o.palette, 9)), [px, py] = o.hand, T = o.release;

  // gather: embers spiral in to the hand
  if (t < T) {
    const k = t / T;
    burst(9, o.seed, (r) => {
      const a0 = r.range(0, TAU), r0 = r.range(9, 14), st = r.range(0, 0.05);
      const u = clamp((t - st) / (T - st));
      if (u <= 0 || u >= 1) return;
      const a = a0 + 2.2 * u, rr = r0 * (1 - ease.inQuad(u)) + 1;
      const x = px + Math.cos(a) * rr, y = py + Math.sin(a) * rr * 0.9;
      const x2 = px + Math.cos(a - 0.35) * (rr + 2), y2 = py + Math.sin(a - 0.35) * (rr + 2) * 0.9;
      p.line(x2, y2, x, y, (v) => (v > 0.6 ? H[2] : H[4]), 0.9);
      p.light(x, y, H[3], 0.3 * u);
    });
    p.glow(px, py, 3 + 5 * k, H[3], 0.25 + 0.35 * k);
    sparkle(p, px, py, 1 + 2 * k, H[2], WHITE, 0.5 * k);
  }
  // release: a white flare and a puff of flame pushed forward
  const u = seg(t, T, T + 0.2);
  if (u > 0 && u < 1) {
    if (u < 0.25) { p.circle(px, py, 3 * (1 - u * 2) + 1, WHITE); p.glow(px, py, 14, H[3], 0.7 * (1 - u * 4)); }
    burst(6, o.seed + 3, (r) => {
      const a = r.range(-0.9, 0.9), sp = r.range(6, 14), s = r.range(1.2, 2.2), f = r.next();
      const d = sp * ease.outCubic(u);
      firePuff(p, px + Math.cos(a) * d, py + Math.sin(a) * d * 0.9, 1 - u, s, f, H, 0.12, Math.cos(a), Math.sin(a));
    });
  }
}
