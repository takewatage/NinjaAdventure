// Fire puff, smoke and spark helpers come from this folder's _lib.js (Sprite Fusion recipe, MIT, Copyright (c) 2026 Hugo Duprez).
import { fit, mix, hex, clamp, smooth, rng, WHITE, TAU } from "../../core/index.js";
import { hotFirst, firePuff, smokePuff, spark, drift } from "./_lib.js";

export const meta = {
  name: "Katon breath (top-down)",
  desc: "A fire-release jutsu breathed to the right, seen from above: a cone of flame puffs roaring out of the mouth, cooling to red and smoke at the far end. Phases: start, loop, end.",
  tags: ["fire", "breath", "jutsu", "ninja", "cone", "magic", "top-down", "directional", "loop"],
  size: [96, 72],
  origin: [16, 36],          // = the character's center
  duration: 0.6,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    mouth: [9, -1],          // where the fire leaves, from the character's center
    spread: 0.42,             // half-angle of the cone (rad)
    phase: "loop",           // "start" | "loop" | "end"
    seed: 3,
  },
};

const D = meta.duration, SMOKE1 = hex("#5b5566");

export function draw(p, t, o) {
  const H = hotFirst(fit(o.palette, 9)), [mx, my] = o.mouth, SP = o.spread, S = o.seed;
  const SMOKE = mix(SMOKE1, H[6], 0.3), SPARKS = [H[0], H[1], H[2], H[4]];
  // which births are allowed: start = only after 0, end = only before 0 (the stream stops at t = 0), loop = all
  const ok = (b) => (o.phase === "start" ? b >= 0 : o.phase === "end" ? b < 0 : true);
  const wob = (b) => 0.12 * Math.sin(b / D * TAU * 2) + 0.06 * Math.sin(b / D * TAU * 3 + 1);   // the cone sways, seamless

  const puffs = [], smoke = [];
  for (let i = 0; i < 120; i++) {
    const r = rng(S, i), base = r.next() * D, life = r.range(0.3, 0.4), a = r.range(-1, 1) * SP;
    const v = r.range(175, 245), s = r.range(1.5, 2.6), f = r.next(), sm = r.chance(0.35), sl = r.range(0.15, 0.25);
    for (let n = -2; n <= 1; n++) {
      const b = base + n * D, age = t - b;
      if (!ok(b) || age < 0 || age > life + (sm ? sl : 0)) continue;
      const ang = a + wob(b), ux = Math.cos(ang), uy = Math.sin(ang);
      const ta = Math.min(age, life), d = (v / 2.6) * (1 - Math.exp(-2.6 * ta));
      const x = mx + ux * d, y = my + uy * d;
      if (age <= life) puffs.push([age / life, x, y, s, f, ux, uy]);
      else smoke.push([(age - life) / sl, x + ux * 6 * (age - life), y + uy * 6 * (age - life), s]);
    }
  }
  for (const [k, x, y, s] of smoke) smokePuff(p, x, y, 1 - k, s * 1.1, SMOKE);
  puffs.sort((a, b) => b[0] - a[0]);      // oldest first, so the hot young puffs sit on top
  for (const [k, x, y, s, f, ux, uy] of puffs) firePuff(p, x, y, 1 - k, s * (0.6 + 2.0 * k), f * 0.6 + k * 0.4, H, 0.1, -ux, -uy);

  // sparks shooting out ahead
  for (let i = 0; i < 12; i++) {
    const r = rng(S + 50, i), base = r.next() * D, life = r.range(0.15, 0.28), a = r.range(-1, 1) * SP, v = r.range(220, 300);
    for (let n = -2; n <= 1; n++) {
      const b = base + n * D, age = t - b;
      if (!ok(b) || age < 0 || age > life) continue;
      const ang = a + wob(b), d = (v / 3) * (1 - Math.exp(-3 * age));
      const vv = v * Math.exp(-3 * age);
      spark(p, mx + Math.cos(ang) * d, my + Math.sin(ang) * d, Math.cos(ang) * vv, Math.sin(ang) * vv, 1 - age / life, SPARKS);
    }
  }

  // the hot root at the mouth (only while fire is coming out)
  const on = o.phase === "start" ? smooth(0, 0.05, t) : o.phase === "end" ? 1 - smooth(0, 0.08, t) : 1;
  if (on > 0.02) {
    firePuff(p, mx + 2, my, 0.95, 2.2 * on, 0, H, 0.2, -1, 0);
    p.dot(mx + 1, my, WHITE, on);
    p.glow(mx + 3, my, 10, H[2], 0.5 * on);
  }
  // light down the cone
  const reach = o.phase === "start" ? smooth(0, 0.25, t) : o.phase === "end" ? 1 - smooth(0.05, 0.35, t) : 1;
  if (reach > 0.02) {
    p.glowLine(mx + 4, my, mx + 42 * Math.max(0.3, reach), my + 10 * wob(t), 14, mix(H[3], WHITE, 0.15), 0.22 * reach);
  }
}
