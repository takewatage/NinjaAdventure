import { fit, hex, clamp, smooth, ease, seg, rng, sparkle, TAU, WHITE } from "../../core/index.js";
const DUST = [hex("#a08a6a"), hex("#cbb894")];

export const meta = {
  name: "Damage set (top-down, 16 px characters)",
  desc: "Top-down damage set for 16 px characters. hit: sparks flung away from the attacker. death: flash, ring, star shards, dust. dizzy: stars circling a knocked-out head (loop).",
  tags: ["hit", "damage", "death", "ko", "dizzy", "stars", "impact", "top-down"],
  size: [72, 72],
  origin: [36, 36],
  duration: 0.8,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#5a1420", "#c9281f", "#ff8a2a", "#ffe26b", "#fff3a6", "#ffffff"],
    stars: ["#7a5a10", "#e0b030", "#ffe680", "#ffffff"],
    phase: "hit",            // "hit" | "death" | "dizzy"
    from: Math.PI,           // hit: the direction the blow comes FROM (PI = from the left, so sparks fly right)
    seed: 4,
  },
};

const SY = 0.8;
function star4(p, x, y, r, c, core) {          // a tiny 4-point star
  if (r < 0.5) return;
  const R = Math.round(r);
  for (let i = -R; i <= R; i++) { p.dot(x + i, y, c); p.dot(x, y + i, c); }
  if (R >= 2) { p.dot(x + 1, y + 1, c); p.dot(x - 1, y - 1, c); p.dot(x + 1, y - 1, c); p.dot(x - 1, y + 1, c); }
  p.dot(x, y, core);
}

export function draw(p, t, o) {
  const C = fit(o.palette, 6), ST = fit(o.stars, 4), S = o.seed;
  if (o.phase === "hit") {
    const away = o.from + Math.PI;
    // white pop
    if (t < 0.07) { const f = 1 - t / 0.07; p.circle(0, 0, 2 + 3 * f, f > 0.5 ? WHITE : C[4]); p.glow(0, 0, 10, C[3], 0.6 * f); }
    // a short cross slash mark, tilted across the blow
    if (t < 0.12) {
      const k = 1 - t / 0.12, L = 6 * ease.outCubic(1 - k) + 2, a = away + Math.PI / 2;
      p.line(-Math.cos(a) * L, -Math.sin(a) * L * SY, Math.cos(a) * L, Math.sin(a) * L * SY, (v) => (Math.abs(v - 0.5) < 0.25 ? WHITE : C[3]), k);
    }
    // sparks flung away from the attacker
    for (let i = 0; i < 9; i++) {
      const r = rng(S, i), a = away + r.range(-0.9, 0.9), sp = r.range(100, 170), life = r.range(0.15, 0.26);
      if (t > life) continue;
      const d = sp / 8 * (1 - Math.exp(-8 * t)), x = Math.cos(a) * d, y = Math.sin(a) * d * SY, k = 1 - t / life;
      const tail = 3 + 4 * k;
      p.line(x - Math.cos(a) * tail, y - Math.sin(a) * tail * SY, x, y, (v) => (v > 0.6 ? WHITE : v > 0.3 ? C[3] : C[2]), Math.min(1, k * 1.5));
    }
    // two little stars
    for (let i = 0; i < 2; i++) {
      const r = rng(S + 9, i), a = away + r.range(-1.2, 1.2), u = seg(t, 0.03, 0.25);
      if (u <= 0 || u >= 1) continue;
      const d = 5 + 7 * ease.outCubic(u);
      star4(p, Math.round(Math.cos(a) * d), Math.round(Math.sin(a) * d * SY), 2 * Math.sin(Math.PI * u), ST[2], WHITE);
    }
    return;
  }
  if (o.phase === "death") {
    // big flash
    if (t < 0.1) { const f = 1 - t / 0.1; p.circle(0, 0, 4 + 7 * (1 - f), f > 0.4 ? WHITE : C[4]); p.glow(0, 0, 26, C[3], 0.8 * f); }
    // a ring on the ground
    const ru = seg(t, 0.03, 0.35);
    if (ru > 0 && ru < 1) {
      const rr = 6 + 18 * ease.outCubic(ru);
      for (let i = 0; i < 40; i++) {
        const a = i / 40 * TAU;
        p.dot(Math.cos(a) * rr, 6 + Math.sin(a) * rr * 0.45, i % 2 ? C[4] : WHITE, 1 - ru);
      }
    }
    // star shards bursting out and falling back
    for (let i = 0; i < 8; i++) {
      const r = rng(S + 20, i), a = i / 8 * TAU + r.range(-0.2, 0.2), sp = r.range(70, 110), life = r.range(0.35, 0.5);
      if (t > life) continue;
      const d = sp / 6 * (1 - Math.exp(-6 * t)), x = Math.cos(a) * d, y = Math.sin(a) * d * SY - 10 * Math.sin(Math.PI * t / life);
      star4(p, Math.round(x), Math.round(y), 2.2 * (1 - t / life) + 0.6, i % 2 ? ST[2] : ST[1], WHITE);
    }
    // dust at the feet as the body hits the ground
    for (let i = 0; i < 5; i++) {
      const r = rng(S + 40, i), a = r.range(0, TAU), u = seg(t, 0.12, 0.55);
      if (u <= 0 || u >= 1) continue;
      const d = 4 + 10 * ease.outCubic(u), x = Math.cos(a) * d, y = 8 + Math.sin(a) * d * 0.4 - 3 * u;
      p.disc(x, y, 2.2 * (1 - u) + 0.5, DUST[i % 2], 1 - u);
    }
    return;
  }
  // dizzy: three stars orbiting, one turn per loop; the far ones dimmer
  const ph = (t / meta.duration) * TAU;
  for (let i = 0; i < 3; i++) {
    const a = ph + i * TAU / 3, x = Math.round(Math.cos(a) * 7), y = Math.round(Math.sin(a) * 2.5), front = Math.sin(a) > 0;
    star4(p, x, y, front ? 2 : 1, front ? ST[2] : ST[1], front ? WHITE : ST[2]);
  }
}
