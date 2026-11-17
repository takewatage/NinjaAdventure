// Fire puff, smoke and spark helpers come from this folder's _lib.js (Sprite Fusion recipe, MIT, Copyright (c) 2026 Hugo Duprez).
import { fit, mix, hex, WHITE, TAU } from "../../core/index.js";
import { noiseFor, pnoise, hotFirst, firePuff, smokePuff, spark, drift, looped } from "./_lib.js";

export const meta = {
  name: "Fireball, small (top-down)",
  desc: "A small top-down fireball flying right for 16 px characters: a churning white-hot head, a short torn tail of flame puffs that the head outruns, a few sparks. Loops while it flies.",
  tags: ["fire", "fireball", "projectile", "magic", "top-down", "directional", "loop"],
  size: [56, 24],
  origin: [42, 12],          // = the center of the head (the projectile's position)
  duration: 0.6,
  loop: true,
  fps: 30,
  bg: "dark",
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    radius: 3,
    speed: 140,              // only shapes the tail; the game moves the sprite
    seed: 4,
  },
};

const D = meta.duration, NL = noiseFor(D), SMOKE1 = hex("#5b5566");

export function draw(p, t, o) {
  const H = hotFirst(fit(o.palette, 9)), R0 = o.radius, V = o.speed, S = o.seed;
  const N = (rate, seed = 0) => NL(t, rate, seed, 0);
  const hx = N(4, S + 1) * 0.4, hy = N(3, S + 2) * 0.5;
  const SMOKE = mix(SMOKE1, H[6], 0.3), SPARKS = [H[1], H[2], H[4], H[5]];

  // tail: flame puffs shed from the back, left behind as the head flies on; a few turn to smoke
  const fire = [], smoke = [];
  looped(t, D, 34, S + 10, (r) => {
    const fl = r.range(0.12, 0.26), sm = r.chance(0.35);
    return { y: r.range(-1, 1) * R0 * 0.8, v: V * r.range(0.15, 0.4), vy: r.range(-10, 10), fl, sm, sl: r.range(0.12, 0.2), s: r.range(1.1, 2.1), f: r.next(), life: fl + (sm ? 0.2 : 0) };
  }, (q, age) => {
    const ta = Math.min(age, q.fl), [wx, y] = drift(0, q.y, q.v, q.vy, ta, 0, 0, 4, 4);
    const x = -R0 * 0.6 + wx - V * ta;
    if (age < q.fl) return fire.push([age, x, y, q]);
    if (!q.sm || age - q.fl > q.sl) return;
    const sa = age - q.fl; smoke.push([sa, x - V * 0.3 * sa, y, q]);
  });
  for (const [sa, x, y, q] of smoke) smokePuff(p, x, y, 1 - sa / q.sl, q.s * 0.8, SMOKE);
  fire.sort((a, b) => b[0] - a[0]);
  for (const [age, x, y, q] of fire) firePuff(p, x, y, 1 - age / q.fl, q.s * (1 + 0.8 * age / q.fl), q.f, H, 0.08, -1, 0);

  // head: a churning ball, swept back a little, white at the heart
  const ph = t / D;
  p.shade(hx - R0 * 2.2, hy - R0 * 1.6, hx + R0 * 1.4, hy + R0 * 1.6, (x, y, out) => {
    x -= hx; y -= hy;
    const d = Math.hypot(x, y), th = Math.atan2(y, x), back = Math.max(0, -Math.cos(th)), a = th / TAU;
    const rim = R0 * (1 + 0.5 * back * back) + 0.5 * pnoise(a * 7 + ph * 8, 7, S);
    if (d > rim) return;
    const h = 1 - d / rim + 0.22 * pnoise(a * 4 - ph * 9 + d * 0.5, 4, S + 3) + 0.1 * (1 - back);
    return h > 0.7 ? H[0] : h > 0.52 ? H[1] : h > 0.36 ? H[3] : h > 0.2 ? H[4] : H[6];
  });

  // sparks flicked off the head
  looped(t, D, 8, S + 20, (r) => ({ a: r.range(-2.6, 2.6), v: r.range(20, 45), life: r.range(0.08, 0.16) }), (q, age) => {
    const d = R0 + q.v * age, x = hx + Math.cos(q.a) * d - V * 0.5 * age, y = hy + Math.sin(q.a) * d;
    spark(p, x, y, Math.cos(q.a) * q.v - V * 0.5, Math.sin(q.a) * q.v, 1 - age / q.life, SPARKS);
  });

  // light
  const fl = 0.85 + 0.15 * N(9, S + 7);
  p.glow(hx - 2, hy, 14, mix(H[3], WHITE, 0.2), 0.35 * fl);
  p.glow(hx, hy, 6, H[1], 0.3 * fl);
}
