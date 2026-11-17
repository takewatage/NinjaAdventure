// Bolt shape and inking come from this folder's _lib.js (adapted from Sprite Fusion's open-source lightning,
// https://www.spritefusion.com/pixel-art-vfx/lightning, MIT License, Copyright (c) 2026 Hugo Duprez).
import { fit, clamp, smooth, ease, seg, sparkle, TAU, WHITE, Rng } from "../../core/index.js";
import { VOLT, PLASMA, zigzag, stroke, crackle, scorch, flight, spark, frameRng } from "./_lib.js";

export const meta = {
  name: "Raiton strike (top-down)",
  desc: "Lightning-release jutsu, top-down, cast right: hands crackle, a sigil marks the ground ahead, a bolt slams down, arcs crawl over the ground, sparks fly, a scorch cools.",
  tags: ["lightning", "electric", "jutsu", "ninja", "strike", "aoe", "magic", "top-down", "directional", "one-shot"],
  size: [128, 140],
  origin: [28, 112],         // = the character's center
  duration: 1.0,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: VOLT, sparks: PLASMA,
    target: [36, 2],         // where the bolt lands, from the character's center (about 2 tiles ahead)
    hand: [6, -3],
    strike: 0.3,             // when the bolt hits (s)
    radius: 14,              // blast radius on the ground (px)
    seed: 4,
  },
};

const SY = 0.75;             // ground ellipse squash, close to the other top-down effects
const FLICK = [1, 1, 0.55, 0.9, 0.7, 0.35, 0.6, 0.25, 0.12];   // brightness per frame after the hit (re-strokes)

export function draw(p, t, o) {
  const C = fit(o.palette, 8), SP = fit(o.sparks, 4), [tx, ty] = o.target, [hx, hy] = o.hand, T = o.strike, R = o.radius;
  const f = Math.floor(t * 30 + 1e-4), a = t - T, fi = Math.floor(a * 30 + 1e-4);

  // ---- before the hit: the hands crackle, a sigil marks the ground
  if (t < T + 0.05) {
    const k = clamp(t / T);
    // hand crackles: a couple of tiny arcs, new every frame
    const r = frameRng(o.seed, f, 1);
    for (let i = 0; i < 2; i++) {
      const ang = r.range(0, TAU), l = r.range(3, 6) * (0.6 + 0.4 * k);
      crackle(p, zigzag(r, hx, hy, hx + Math.cos(ang) * l, hy + Math.sin(ang) * l * 0.8, 0.4, 0.2), 0.5 + 0.4 * k, C, 0.35);
    }
    p.glow(hx, hy, 6 + 4 * k, C[4], 0.3 + 0.3 * k);
    // the sigil: a dashed ring drawn in and spinning, brightening; a cross at its heart
    const rx = R * 0.8, spin = t * 5, reveal = smooth(0, 0.15, t);
    for (let i = 0; i < 16; i++) {
      if (i / 16 > reveal || i % 4 === 3) continue;
      const ang = i / 16 * TAU + spin;
      p.dot(tx + Math.cos(ang) * rx, ty + Math.sin(ang) * rx * SY, k > 0.7 ? C[6] : C[4], 0.6 + 0.4 * k);
    }
    if (f % 2 === 0) { p.dot(tx, ty, C[6], k); p.dot(tx - 2, ty, C[4], k); p.dot(tx + 2, ty, C[4], k); p.dot(tx, ty - 1, C[4], k); p.dot(tx, ty + 1, C[4], k); }
    p.glow(tx, ty, 10, C[3], 0.2 * k);
    // the sky darkens a little over the target (a hint the bolt is coming)
    if (k > 0.6) {
      const r2 = frameRng(o.seed, f, 2);
      if (r2.chance(0.5)) crackle(p, zigzag(r2, tx + r2.range(-10, 10), -102, tx + r2.range(-14, 14), -84, 0.4, 0.3), 0.4, C, 0.2, 0.7);
    }
  }

  // ---- scorch left on the ground, under the strike
  if (a >= 0) scorch(p, tx, ty - R * 0.25 * SY, R * 0.7, Math.max(0, 1 - a / 0.5), 1 - smooth(0.4, 0.7, a), R * 0.7 * SY);

  // ---- the bolt, from the top of the frame to the target; re-strokes flicker it for a few frames
  if (a >= 0 && fi < FLICK.length) {
    const k = FLICK[fi], R2 = new Rng(o.seed * 31 + (fi < 2 ? 0 : fi >> 1));   // same shape for the first 2 frames, then new
    const b = zigzag(R2, tx + R2.range(-8, 8), -104, tx, ty, 0.22, 0.45);
    stroke(p, b, k, C, 0.8, { hero: fi === 0, light: 0.6, core: fi < 2 ? 1 : 0 });
    if (fi < 2) {
      p.circle(tx, ty, 6 - fi * 2, WHITE);
      p.glow(tx, ty, 30, C[5], 0.9 - fi * 0.3);
      p.glow(tx, -40, 24, C[4], 0.4 - fi * 0.15);
    }
  }

  // ---- shock ring on the ground
  const ru = seg(a, 0, 0.25);
  if (ru > 0 && ru < 1) {
    const rr = 4 + (R + 6) * ease.outCubic(ru), fade = 1 - ru;
    p.shade(tx - rr - 2, ty - rr * SY - 2, tx + rr + 2, ty + rr * SY + 2, (x, y, out) => {
      const q = Math.abs(Math.hypot(x - tx, (y - ty) / SY) - rr);
      if (q > 1.4) return;
      out.c = fade > 0.6 ? C[6] : C[4]; out.a = fade * (1 - q / 1.8);
    });
  }

  // ---- arcs crawling over the ground from the strike point, new every 2 frames
  if (a >= 0 && a < 0.45) {
    const k = 1 - a / 0.45, r = frameRng(o.seed, Math.floor(fi / 2), 3);
    const n = a < 0.15 ? 4 : 2;
    for (let i = 0; i < n; i++) {
      const ang = r.range(0, TAU), l = r.range(R * 0.6, R * 1.25);
      const b = zigzag(r, tx, ty, tx + Math.cos(ang) * l, ty + Math.sin(ang) * l * SY, 0.35, 0.5);
      crackle(p, b, 0.35 + 0.6 * k, C, 0.35);
    }
  }

  // ---- sparks thrown out (gravity pulls them back to the ground at the strike's y)
  if (a >= 0) {
    const r = new Rng(o.seed + 77);
    for (let i = 0; i < 12; i++) {
      const ang = r.range(-Math.PI, 0), sp = r.range(70, 140), life = r.range(0.25, 0.5), side = r.range(-1, 1);
      if (a > life) continue;
      const vx = Math.cos(ang) * sp, vy = Math.sin(ang) * sp * 0.8;
      const [x, y, ux, uy] = flight(tx, ty, vx, vy, a, { g: 0.4, drag: 2.5, floor: ty + side * R * 0.5 * SY, bounce: 0.35 });
      spark(p, x, y, ux, uy, 1 - a / life, SP);
    }
  }
  // ---- lingering glints
  if (a > 0.15 && a < 0.6) {
    const r = new Rng(o.seed + 91);
    for (let i = 0; i < 4; i++) {
      const t0 = r.range(0.15, 0.4), life = 0.18, u = (a - t0) / life, ang = r.range(0, TAU), d = r.range(3, R);
      if (u < 0 || u > 1) continue;
      sparkle(p, tx + Math.cos(ang) * d, ty + Math.sin(ang) * d * SY, 2.5 * Math.sin(Math.PI * u), C[6], WHITE, 0.5);
    }
  }
}
