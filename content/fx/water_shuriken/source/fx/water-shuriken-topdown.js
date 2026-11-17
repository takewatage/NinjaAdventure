// Droplets use this folder's bead() (adapted from Sprite Fusion's open-source blood, MIT, Copyright (c) 2026 Hugo Duprez).
import { fit, mix, clamp, TAU, WHITE, rng } from "../../core/index.js";
import { WATER, bead } from "./_lib.js";

export const meta = {
  name: "Water shuriken (top-down)",
  desc: "A spinning four-bladed star of water flying right, seen from above: curved blades lit on their leading edges, smears off the tips, droplets and mist shed behind. Loops.",
  tags: ["water", "shuriken", "projectile", "ninja", "magic", "top-down", "directional", "loop"],
  size: [56, 32],
  origin: [40, 16],          // = the center of the star (the projectile's position)
  duration: 0.4,
  loop: true,
  fps: 30,
  bg: "dark",
  options: { palette: WATER, radius: 7, speed: 200, turns: 1, seed: 2 },
};

const D = meta.duration;
// φ in [0, π/2): angle inside one blade sector; blades curve back against the spin
function star(p, C, R, rot) {
  const B = R + 2.5;
  p.shade(-B, -B, B, B, (x, y, out) => {
    const r = Math.hypot(x, y);
    if (r > R + 0.5) return;
    const th = Math.atan2(y, x) - rot;
    // blade center line bends backwards with radius (spin is clockwise on screen = +angle)
    let phi = ((th + 0.55 * r / R) % (Math.PI / 2) + Math.PI / 2) % (Math.PI / 2) - Math.PI / 4;
    const u = r / R, half = 0.74 * Math.pow(1 - u, 0.9) + 0.03;
    const inBlade = Math.abs(phi) < half;
    if (r < 1.1) { out.c = C[1]; out.a = 0.9; return; }          // the hole in the middle
    if (r < 2.6) { out.c = r < 1.9 ? C[6] : C[4]; return; }       // the hub ring
    if (!inBlade) return;
    const edge = half - Math.abs(phi);                             // distance to the blade's edge (radians)
    const lead = phi > 0;                                          // leading side of the blade (spin direction)
    if (edge < 0.09) { out.c = lead ? C[6] : C[2]; return; }       // a bright cutting edge in front, deep rim behind
    out.c = lead ? (u < 0.55 ? C[5] : C[4]) : (u < 0.5 ? C[4] : C[3]);
    if (lead && u > 0.35 && u < 0.6 && edge < 0.22) out.c = WHITE;   // a glint along the leading edge
  });
  // tip smears: thin arcs trailing each tip, fading
  for (let b = 0; b < 4; b++) {
    const tipA = rot + b * Math.PI / 2 - 0.55;
    for (let i = 1; i <= 6; i++) {
      const a = tipA - i * 0.13, rr = R - 0.6 - i * 0.12;
      p.dot(Math.cos(a) * rr, Math.sin(a) * rr, i < 3 ? C[5] : C[4], 0.85 * (1 - i / 7));
    }
  }
}

export function draw(p, t, o) {
  const C = fit(o.palette, 8), R = o.radius, V = o.speed, S = o.seed;
  const rot = (t / D) * o.turns * TAU;   // quarter turns per loop keep it seamless (4-fold star); 1 turn = 30 deg a frame


  // droplets flung off the tips, left behind as the star flies on
  for (let i = 0; i < 14; i++) {
    const r = rng(S, i), born = r.next() * D, life = r.range(0.12, 0.24), a0 = r.range(0, TAU), sp = r.range(25, 55), s = r.chance(0.3) ? 2 : 1;
    for (let age = ((t - born) % D + D) % D; age < life; age += D) {
      const vx = Math.cos(a0) * sp - V * 0.7, vy = Math.sin(a0) * sp;
      const x = Math.cos(a0) * R + vx * age, y = Math.sin(a0) * R + vy * age;
      bead(p, x, y, vx, vy, s, C, 1 - age / life);
    }
  }
  p.glow(0, 0, R + 6, C[4], 0.22);
  star(p, C, R, rot);
  p.glow(0, 0, R * 0.8, C[6], 0.18);
}
