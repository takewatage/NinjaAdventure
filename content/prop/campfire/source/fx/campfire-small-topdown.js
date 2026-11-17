// Flame tongue, puff, lick, smoke and ember helpers come from this folder's _lib.js
// (Sprite Fusion's open-source fire recipe, MIT License, Copyright (c) 2026 Hugo Duprez).
import { fit, mix, hex, clamp, smooth, ease, seg, WHITE } from "../../core/index.js";
import { noiseFor, hotFirst, flameTongue, firePuff, lick, smokePuff, ember, spark, drift, looped, LAYERS, BACK_LAYERS } from "./_lib.js";

export const meta = {
  name: "Campfire, small (top-down)",
  desc: "A small campfire for 16 px top-down maps, a save point: crossed logs in a ring of stones. States: unlit (cold logs and ash), ignite (a spark catches) and lit (a looping fire).",
  tags: ["fire", "campfire", "prop", "save-point", "light", "top-down", "loop"],
  size: [48, 48],
  origin: [24, 36],          // = the center of the fire pit on the ground
  duration: 1.2,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#4a1712", "#8a1f17", "#c9281f", "#f2561d", "#ff8a2a", "#ffc23d", "#ffe26b", "#fff3a6", "#ffffff"],
    wood: ["#140c0c", "#2a1812", "#46291a", "#6b4325", "#94653a", "#c19560"],
    stone: ["#1b1820", "#36313f", "#544d5e", "#787083", "#a19aab"],
    state: "lit",            // "unlit" | "ignite" | "lit"
    height: 12,
    seed: 2,
  },
};

const D = meta.duration, NL = noiseFor(D), SMOKE1 = hex("#5b5566"), ASH = [hex("#1e1a20"), hex("#2f2a33"), hex("#4a4450")];
// stones round the pit: [x, y, rx, ry]; y < 0 are the far ones (drawn behind the logs)
const STONES = [[-10, 0, 2.6, 1.9], [-7.5, -3.2, 2.4, 1.7], [-2.6, -4.6, 2.5, 1.7], [2.6, -4.6, 2.4, 1.7], [7.5, -3.2, 2.5, 1.8],
                [10, 0, 2.6, 1.9], [7, 3.3, 2.7, 2], [0, 4.4, 2.8, 2], [-7, 3.3, 2.7, 2]];
// logs: from (x0,y0) near end to (x1,y1) far end, radius
const LOGS = [[-7, 2.2, 5.5, -3, 1.6], [7, 2.2, -5.5, -3, 1.6]];
// tongues: [x, base y, height share, half-width, back?]
const TONGUES = [[-3.2, -1.5, 0.55, 1.6, 1], [3.2, -1.5, 0.6, 1.6, 1], [0, -1, 1, 2.3, 0], [-1.6, 0, 0.7, 1.7, 0], [1.8, 0, 0.66, 1.6, 0]];

function stone(p, S, x, y, rx, ry) {
  p.shade(x - rx - 1, y - ry - 1, x + rx + 1, y + ry + 1, (px, py, out) => {
    const dx = (px - x) / rx, dy = (py - y) / ry, d = dx * dx + dy * dy;
    if (d > 1) return;
    out.c = d > 0.62 ? S[0] : dy < -0.2 && dx < 0.4 ? (d < 0.25 ? S[4] : S[3]) : dy > 0.35 ? S[1] : S[2];
  });
}
function log(p, W, [x0, y0, x1, y1, r], burn, H) {
  const len = Math.hypot(x1 - x0, y1 - y0), ux = (x1 - x0) / len, uy = (y1 - y0) / len, nx = -uy, ny = ux;
  p.shade(Math.min(x0, x1) - r - 1, Math.min(y0, y1) - r - 1, Math.max(x0, x1) + r + 1, Math.max(y0, y1) + r + 1, (px, py, out) => {
    const dx = px - x0, dy = py - y0, s = dx * ux + dy * uy, q = dx * nx + dy * ny;
    if (s < 0 || s > len || Math.abs(q) > r) return;
    const v = q / r;                                   // -1 .. 1 across the log
    out.c = Math.abs(v) > 0.75 ? W[1] : v < -0.2 ? W[4] : v < 0.35 ? W[3] : W[2];
    if (Math.abs(v) < 0.75 && ((s * 1.7) | 0) % 3 === 0) out.c = v < 0 ? W[3] : W[2];   // bark grain
    // charred middle, glowing when lit
    const mid = Math.abs(s - len * 0.62) < len * 0.2;
    if (mid) out.c = burn > 0.05 && Math.abs(v) < 0.6 && ((px * 3 + py * 5) & 3) !== 0 ? (burn > 0.6 ? H[4] : H[6]) : Math.abs(v) > 0.75 ? W[0] : W[1];
  });
  // the cut end facing us
  p.shade(x0 - r - 1, y0 - r - 1, x0 + r + 1, y0 + r + 1, (px, py, out) => {
    const d = Math.hypot(px - x0, (py - y0) * 1.1) / r;
    if (d > 1) return;
    out.c = d > 0.7 ? W[2] : d > 0.35 ? W[5] : W[4];
  });
}

export function draw(p, t, o) {
  const H = hotFirst(fit(o.palette, 9)), W = fit(o.wood, 6), ST = fit(o.stone, 5), S = o.seed, HC = o.height;
  const N = (rate, seed = 0, off = 0) => NL(t, rate, seed, off);
  const state = o.state;
  // how lit the fire is: 0 cold, 1 full
  const on = state === "lit" ? 1 : state === "ignite" ? ease.outCubic(seg(t, 0.1, 0.75)) : 0;
  const fl = 0.8 + 0.12 * N(7.3, S + 1) + 0.08 * N(19, S + 2);
  const GLOW = mix(mix(H[3], H[4], 0.5), WHITE, 0.25), SMOKE = mix(SMOKE1, H[6], 0.25), EMB = [H[1], H[2], H[4], H[6]], SPARKS = [H[1], H[2], H[4], H[5]];

  // (no baked floor light: use a PointLight2D in the game so it lights the map and characters)
  // ash bed, with coals when lit
  p.shade(-8, -4, 8, 4, (x, y, out) => {
    const d = (x / 7.5) ** 2 + (y / 3.4) ** 2;
    if (d > 1) return;
    const n = ((x * 7 + y * 13 + 99) * 2654435761 >>> 28) & 7;
    out.c = n < 2 ? ASH[2] : n < 5 ? ASH[1] : ASH[0];
    if (on > 0.05 && n >= 5 && d < 0.8) out.c = N(6, S + n * 3, x * 0.3) > 0.1 ? H[3] : H[5];
  });
  for (const s of STONES) if (s[1] < 0) stone(p, ST, ...s);

  // smoke rising from the fire (lit) or a thin wisp while it catches
  if (on > 0) looped(t, D, 10, S + 300, (r) => ({ x: r.range(-2, 2), vx: r.range(-2, 2), vy: -r.range(9, 14), life: r.range(0.9, 1.2), s: r.range(1.4, 2.2) }), (q, age) => {
    const [x, y] = drift(q.x, -HC * 0.9, q.vx, q.vy, age, 3, -10, 1.2, 0.8);
    smokePuff(p, x + NL(t - age, 0.8, S + 60) * (1 + 2 * age), y, (1 - age / q.life) * on * on * on, q.s, SMOKE);
  });

  for (const L of LOGS) log(p, W, L, on, H);

  if (on > 0) {
    const tongue = (i) => {
      const [dx, y, hs, w, back] = TONGUES[i], n = (S * 7 + i) * 13;
      const leap = Math.max(0, N(2.6, n + 70) - 0.55) * 1.2;
      const h = (HC * hs * (1 + 0.22 * N(3.3, n) + leap)) * fl * on;
      flameTongue(p, dx, y, h, w * (0.6 + 0.4 * on), N(2.2, n + 40) * (1 + h * 0.08), N, n, H, back ? BACK_LAYERS : LAYERS, 0.45, 0.8 + h * 0.05);
      return [dx + N(2.2, n + 40), y - h * 0.85];
    };
    for (let i = 0; i < TONGUES.length; i++) if (TONGUES[i][4]) tongue(i);
    // little flames licking off the coals
    looped(t, D, 20, S + 210, (r) => ({ x: r.range(-5, 5), y: -r.range(1, 3), vx: r.range(-3, 3), vy: -r.range(14, 24), life: r.range(0.14, 0.24), s: r.range(0.8, 1.3), f: r.next() }), (q, age) => {
      const [x, y] = drift(q.x, q.y, q.vx, q.vy, age, 0, -70, 5, 3.2);
      firePuff(p, x, y, (1 - age / q.life), q.s * on, q.f, H, 0.1);
    });
    const tips = [];
    for (let i = 0; i < TONGUES.length; i++) if (!TONGUES[i][4]) tips.push(tongue(i));
    looped(t, D, 12, S + 220, (r, j) => ({ i: j % tips.length, vx: r.range(-2, 2), vy: -r.range(10, 18), s: r.range(0.7, 1.2), life: 0.22 }), (q, age) => {
      const [tx, ty] = tips[q.i];
      lick(p, tx + q.vx * age, ty - 1 + q.vy * age, 1 - age / q.life, q.s * on, H);
    });
    // embers drifting up
    looped(t, D, 10, S + 500, (r) => ({ x: r.range(-4, 4), y: -r.range(5, 10), vx: r.range(-8, 8), vy: -r.range(18, 32), life: r.range(0.6, 1.1), a: r.range(0, 6.3) }), (q, age) => {
      const [x, y] = drift(q.x, q.y, q.vx, q.vy, age, 0, -15, 1.6, 1.6);
      if (on > 0.5) ember(p, x + 3 * (Math.sin(age * 2.6 + q.a) - Math.sin(q.a)), y, 1 - age / q.life, 1, EMB, age * 40 + q.a);
    });
    p.glow(0, -HC * 0.4, 16, GLOW, 0.18 * on * fl);
    p.glow(0, -3, 8, H[1], 0.25 * on * fl);
  }

  // ignite: a struck spark and a pop of sparks as it catches
  if (state === "ignite") {
    if (t < 0.12) {
      const f = 1 - t / 0.12;
      p.px(0, -2, WHITE);
      p.glow(0, -2, 10, H[1], 0.8 * f);
    }
    for (let j = 0; j < 7; j++) {
      const a = -Math.PI / 2 + (j - 3) * 0.32, sp = 60 + (j * 37 % 40), life = 0.35, age = t - 0.05;
      if (age < 0 || age > life) continue;
      const [x, y, vx, vy] = drift(0, -2, Math.cos(a) * sp, Math.sin(a) * sp, age, 0, 200, 2, 2);
      spark(p, x, y, vx, vy, 1 - age / life, SPARKS);
    }
  }
  for (const s of STONES) if (s[1] >= 0) stone(p, ST, ...s);
}
