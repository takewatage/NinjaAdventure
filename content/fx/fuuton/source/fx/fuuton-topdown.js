import { fit, clamp, smooth, ease, seg, rng, sparkle, TAU, WHITE } from "../../core/index.js";
import { drawLeaf } from "./_lib.js";

export const meta = {
  name: "Fuuton wind ball (top-down)",
  desc: "Wind-release jutsu, top-down: wind gathers in the hand (cast), then a ball of spinning wind crescents flies right with speed lines and swirling leaves (fly, loops).",
  tags: ["wind", "air", "jutsu", "ninja", "projectile", "magic", "top-down", "directional", "loop"],
  size: [64, 40],
  origin: [40, 20],          // fly: the ball's center. cast: the character's center
  duration: 0.4,
  loop: true,
  fps: 30,
  bg: "dark",
  options: {
    palette: ["#2a4a52", "#5b9aa0", "#a6e0dc", "#e2fbf6", "#ffffff"],
    leaves: ["#123818", "#2f7a2a", "#6cb83a", "#c8f070"],
    phase: "fly",            // "cast" | "fly"
    radius: 6,
    hand: [10, 0],
    seed: 3,
  },
};

const D = meta.duration;

// a crescent of wind: an arc of thickness w round (cx, cy) at radius r from angle a0, length len (radians)
function crescent(p, C, cx, cy, r, a0, len, w, k, sy = 1) {
  const n = Math.max(6, Math.round(len * r * 1.2));
  for (let i = 0; i <= n; i++) {
    const v = i / n, a = a0 - v * len, th = w * Math.sin(Math.PI * Math.min(1, v * 1.25 + 0.05)) * (1 - v * 0.4);
    const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r * sy;
    const c = v < 0.18 ? C[4] : v < 0.5 ? C[3] : C[2];
    p.dot(x, y, c, k * (1 - v * 0.6));
    if (th > 0.8) p.dot(x - Math.cos(a) * 1, y - Math.sin(a) * sy, v < 0.4 ? C[3] : C[2], k * (1 - v * 0.7));
  }
}

export function draw(p, t, o) {
  const C = fit(o.palette, 5), L = fit(o.leaves, 4), R = o.radius, S = o.seed, ph = t / D;
  if (o.phase === "cast") {
    const [hx, hy] = o.hand, k = clamp(t / 0.3);
    // streaks pulled in towards the hand, spinning
    for (let i = 0; i < 6; i++) {
      const r = rng(S, i), a0 = r.range(0, TAU), st = r.range(0, 0.08), u = clamp((t - st) / 0.28);
      if (u <= 0 || u >= 1) continue;
      const a = a0 + 4 * u, rr = 14 * (1 - ease.inQuad(u)) + 3;
      crescent(p, C, hx, hy, rr, a, 1.2, 1.5, 0.9 * Math.sin(Math.PI * u), 0.85);
    }
    // the ball forming
    if (k > 0.3) {
      const g = (k - 0.3) / 0.7;
      for (let j = 0; j < 3; j++) crescent(p, C, hx, hy, R * g, t * 30 + j * TAU / 3, 1.6, 1.6, g);
      p.glow(hx, hy, 8 * g, C[3], 0.3 * g);
    }
    return;
  }
  // ---- fly: speed lines behind
  for (let i = 0; i < 5; i++) {
    const r = rng(S + 10, i), y = r.range(-R + 1, R - 1), len = r.range(8, 16), off = ((ph * 2 + r.next()) % 1) * 10;
    p.line(-R - 2 - off, y, -R - 2 - off - len * (1 - off / 12), y, off < 5 ? C[2] : C[1]);
  }
  // leaves caught in the swirl, trailing behind
  for (let i = 0; i < 4; i++) {
    const r = rng(S + 20, i), a = (ph + i / 4) * TAU * 2, rr = R + 2 + r.range(0, 3);
    drawLeaf(p, Math.cos(a) * rr - 3, Math.sin(a) * rr * 0.8, 3.5, 1.2, a * 1.5, a * 3, L);
  }
  // the ball: three wind crescents spinning (one turn per loop keeps it seamless), a bright heart
  p.glow(0, 0, R + 5, C[2], 0.3);
  p.disc(0, 0, R * 0.6, C[2]);
  p.disc(-0.5, -0.5, R * 0.35, C[3]);
  for (let j = 0; j < 3; j++) crescent(p, C, 0, 0, R, ph * TAU * 2 + j * TAU / 3, 1.9, 2.2, 1);
  for (let j = 0; j < 2; j++) crescent(p, C, 0, 0, R * 0.55, -ph * TAU * 2 + j * Math.PI, 1.6, 1.2, 0.9);
  p.dot(0, 0, WHITE);
}
