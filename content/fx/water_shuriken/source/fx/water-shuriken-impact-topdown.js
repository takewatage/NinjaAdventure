import { fit, mix, hex, clamp, smooth, ease, seg, burst, fly, flyV, WHITE, TAU } from "../../core/index.js";
import { WATER, bead, ring } from "./_lib.js";

export const meta = {
  name: "Water shuriken impact (top-down)",
  desc: "A water shuriken bursting on a hit, seen from above: a cyan flash and an X cut, the star shatters into a crown of droplets, rings spread on the ground and a puddle fades.",
  tags: ["water", "shuriken", "impact", "splash", "ninja", "magic", "top-down", "one-shot"],
  size: [56, 56],
  origin: [28, 28],          // = the impact point
  duration: 0.55,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: WATER, radius: 8, puddle: true, seed: 9 },
};

const SY = 0.85;

export function draw(p, t, o) {
  const C = fit(o.palette, 8), R = o.radius, k0 = R / 8;
  // puddle, under everything: appears with the splash, then shrinks away as it soaks in
  if (o.puddle) {
    const grow = smooth(0.04, 0.12, t), shrink = 1 - smooth(0.22, 0.55, t), pr = R * 0.75 * grow * shrink;
    if (pr > 0.8) p.shade(-pr - 1, -pr, pr + 1, pr, (x, y, out) => {
      const d = Math.hypot(x, y / SY) / pr;
      if (d > 1) return;
      out.c = d > 0.78 ? C[3] : C[2];
      if (d < 0.45 && x < -pr * 0.15 && y < -pr * 0.1) out.c = C[4];   // a catch-light on the far side
    });
  }
  // flash and an X cut (the blades' last bite)
  if (t < 0.1) {
    const f = 1 - t / 0.1;
    p.circle(0, 0, 3 * f + 1.5, f > 0.5 ? WHITE : C[6]);
    p.glow(0, 0, 18 * k0, C[5], 0.7 * f);
    const L = (5 + 4 * (1 - f)) * k0;
    p.line(-L, -L * 0.8, L, L * 0.8, (v) => (Math.abs(v - 0.5) < 0.2 ? WHITE : C[6]), f);
    p.line(-L, L * 0.8, L, -L * 0.8, (v) => (Math.abs(v - 0.5) < 0.2 ? WHITE : C[6]), f);
  }
  // rings spreading on the ground
  const r1 = seg(t, 0.02, 0.35), r2 = seg(t, 0.1, 0.5);
  if (r1 > 0 && r1 < 1) ring(p, 0, 0, (3 + (R + 6) * ease.outCubic(r1)), SY, 1 - r1, C, { n: 1, hot: r1 < 0.3, glint: 1, seed: 1 });
  if (r2 > 0 && r2 < 1) ring(p, 0, 0, (2 + (R + 1) * ease.outCubic(r2)), SY, (1 - r2) * 0.8, C, { n: 1, seed: 2 });
  // a crown of droplets thrown out and falling back (they shrink as they come down toward the ground)
  burst(18, o.seed, (r) => {
    const a = r.range(0, TAU), sp = r.range(40, 90) * k0, life = r.range(0.2, 0.38), s = r.chance(0.35) ? 2 : 1;
    if (t > life) return;
    const vx = Math.cos(a) * sp, vy = Math.sin(a) * sp * SY;
    const [x, y] = fly(0, 0, vx, vy, t, 0, 5), [ux, uy] = flyV(vx, vy, t, 0, 5);
    const k = 1 - t / life;
    bead(p, x, y, ux, uy, k > 0.4 ? s : 1, C, Math.min(1, k * 2));
    if (k < 0.2) p.dot(x, y, C[4], k * 4);   // tiny landing fleck
  });
  // a few blade shards spinning out
  burst(4, o.seed + 1, (r, i) => {
    const a = i * TAU / 4 + r.range(-0.3, 0.3) + 0.7, sp = r.range(50, 70) * k0, life = r.range(0.16, 0.24);
    if (t > life) return;
    const [x, y] = fly(0, 0, Math.cos(a) * sp, Math.sin(a) * sp * SY, t, 0, 7), spin = a + t * 30, L = 2;
    p.line(x - Math.cos(spin) * L, y - Math.sin(spin) * L, x + Math.cos(spin) * L, y + Math.sin(spin) * L, (v) => (v > 0.5 ? C[6] : C[4]), 1 - t / life);
  });
  // central splash blob collapsing
  const cu = seg(t, 0.02, 0.2);
  if (cu > 0 && cu < 1) {
    const rr = 4 * k0 * (1 - cu);
    p.circle(0, 0, rr + 0.8, C[4], 1 - cu);
    p.circle(-0.4, -0.5, rr * 0.6, C[6], 1 - cu);
  }
}
