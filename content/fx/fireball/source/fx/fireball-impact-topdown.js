import { fit, mix, hex, clamp, smooth, ease, seg, burst, fly, flyV, WHITE, TAU } from "../../core/index.js";
import { hotFirst, firePuff, smokePuff, spark } from "./_lib.js";

export const meta = {
  name: "Fireball impact (top-down)",
  desc: "A small fireball bursting on the ground, seen from above: white flash, a ring of flame puffs cooling, a flat shock ring, sparks, a little smoke and a fading scorch.",
  tags: ["fire", "fireball", "impact", "explosion", "magic", "top-down", "one-shot"],
  size: [64, 64],
  origin: [32, 32],          // = the impact point
  duration: 0.6,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    radius: 12,              // blast radius in px (splash damage area)
    scorch: true,
    seed: 8,
  },
};

const SY = 0.85, SOOT = hex("#1a1214"), SMOKE1 = hex("#5b5566");

export function draw(p, t, o) {
  const H = hotFirst(fit(o.palette, 9)), R = o.radius, k0 = R / 12;
  const SMOKE = mix(SMOKE1, H[6], 0.3), SPARKS = [H[0], H[1], H[2], H[4]];

  // scorch on the ground, under everything
  if (o.scorch) {
    const a = 0.55 * smooth(0.02, 0.1, t) * (1 - smooth(0.3, 0.6, t));
    if (a > 0) p.shade(-R, -R * SY, R, R * SY, (x, y, out) => {
      const d = Math.hypot(x, y / SY) / (R * 0.7);
      if (d > 1) return;
      out.c = SOOT; out.a = a * (1 - d * d);
    });
  }
  // flash
  if (t < 0.08) {
    const f = 1 - t / 0.08;
    p.circle(0, 0, (4 + 4 * (1 - f)) * k0, f > 0.5 ? WHITE : H[1]);
    p.glow(0, 0, 26 * k0, H[3], 0.9 * f);
  }
  // flat shock ring
  const ru = seg(t, 0.02, 0.28);
  if (ru > 0 && ru < 1) {
    const rr = (5 + (R + 6 - 5) * ease.outCubic(ru)) , fade = 1 - ru;
    p.shade(-rr - 2, -rr * SY - 2, rr + 2, rr * SY + 2, (x, y, out) => {
      const q = Math.abs(Math.hypot(x, y / SY) - rr);
      if (q > 1.3) return;
      out.c = fade > 0.6 ? H[1] : H[3]; out.a = fade * (1 - q / 1.6);
    });
  }
  // flame puffs thrown out in a ring, cooling as they slow
  const puffs = [];
  burst(14, o.seed, (r) => {
    const a = r.range(0, TAU), sp = r.range(30, 60) * k0, life = r.range(0.22, 0.38), s = r.range(1.6, 3) * k0, f = r.next(), st = r.range(0, 0.04);
    const u = t - st;
    if (u < 0 || u > life) return;
    const [x, y] = fly(0, 0, Math.cos(a) * sp, Math.sin(a) * sp * SY, u, 0, 6);
    puffs.push([u / life, x, y, s, f, a]);
  });
  // smoke that lingers after
  burst(6, o.seed + 1, (r) => {
    const a = r.range(0, TAU), d = r.range(2, R * 0.8), st = r.range(0.18, 0.28), life = r.range(0.25, 0.35), s = r.range(2, 3) * k0;
    const u = t - st;
    if (u < 0 || u > life) return;
    smokePuff(p, Math.cos(a) * d, Math.sin(a) * d * SY - 6 * u, 1 - u / life, s, SMOKE);
  });
  puffs.sort((a, b) => b[0] - a[0]);
  for (const [v, x, y, s, f, a] of puffs) firePuff(p, x, y, 1 - v, s * (1 + 0.6 * v), f, H, 0.1, Math.cos(a), Math.sin(a));
  // core: a hot blob that shrinks
  const cu = seg(t, 0.03, 0.22);
  if (cu > 0 && cu < 1) firePuff(p, 0, 0, 1 - cu, 4 * k0 * (1 - 0.5 * cu), 0, H, 0.2, 0, 0);
  // sparks
  burst(10, o.seed + 2, (r) => {
    const a = r.range(0, TAU), sp = r.range(70, 120) * k0, life = r.range(0.15, 0.3);
    if (t > life) return;
    const vx = Math.cos(a) * sp, vy = Math.sin(a) * sp * SY;
    const [x, y] = fly(0, 0, vx, vy, t, 0, 6), [ux, uy] = flyV(vx, vy, t, 0, 6);
    spark(p, x, y, ux, uy, 1 - t / life, SPARKS);
  });
}
