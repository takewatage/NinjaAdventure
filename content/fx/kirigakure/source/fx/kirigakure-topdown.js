import { fit, clamp, smooth, ease, seg, sparkle, rng, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Kirigakure mist (top-down)",
  desc: "Hiding-in-mist jutsu, top-down: a poof of mist swallows the body and thins to wisps (enter), wisps creep round the feet (loop), mist bursts away as it lifts (exit).",
  tags: ["mist", "smoke", "stealth", "invisible", "jutsu", "ninja", "top-down", "loop"],
  size: [72, 64],
  origin: [36, 38],          // = the character's center
  duration: 1.2,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#3d4a5c", "#7f90a6", "#b4c2d3", "#e6eef7"],
    phase: "loop",           // "enter" | "loop" | "exit" | "veil" (soft mist that swirls round while the body fades)
    layer: "all",            // for "veil": "back" (behind the character), "front", or "all"
    seed: 6,
  },
};

const D = meta.duration, SY = 0.6, FEET = 7;

// a pixel cloud: a dark rim, a pale body, a bright cap; k fades it, edges dither
function puff(p, C, x, y, r, k) {
  if (k <= 0.03 || r < 0.6) return;
  r *= 0.45 + 0.55 * Math.min(1, k * 1.3);                       // fading puffs shrink rather than go see-through
  p.disc(x, y + r * 0.15, r, C[1], 0.6 * k * k);                  // the dark rim goes first so fading mist never looks dirty
  p.disc(x, y, r * 0.78, C[2], Math.min(1, 1.5 * k));
  p.disc(x - r * 0.25, y - r * 0.3, r * 0.42, C[3], Math.min(1, 1.6 * k));
}

export function draw(p, t, o) {
  const C = fit(o.palette, 4), S = o.seed, ph = o.phase;
  if (ph === "veil") return veil(p, C, S, t, o.layer);

  if (ph === "enter" || ph === "exit") {
    const enter = ph === "enter", dur = enter ? 0.7 : 0.5;
    // the poof: puffs thrown out from the body, growing, then thinning
    const N = 16;
    for (let i = 0; i < N; i++) {
      const r = rng(S + (enter ? 0 : 50), i), a = (i / N) * TAU + r.range(-0.2, 0.2), st = r.range(0, 0.06);
      const d0 = r.range(1, 4), d1 = r.range(9, 15), h = r.range(-12, 2), size = r.range(3.2, 5.2), life = dur * r.range(0.7, 1);
      const u = (t - st) / life;
      if (u < 0 || u > 1) continue;
      const d = d0 + (d1 - d0) * ease.outCubic(u);
      const x = Math.cos(a) * d, y = Math.sin(a) * d * SY + h * (1 - u * 0.5) + (FEET - h) * 0.3 * u - 2 * u;
      const k = Math.min(1, u * 8) * (1 - smooth(enter ? 0.45 : 0.3, 1, u));
      puff(p, C, x, y, size * (0.5 + 0.7 * ease.outCubic(u)), k);
    }
    // a dense core covering the body at the peak (the moment the character vanishes / reappears)
    const cu = seg(t, 0, enter ? 0.45 : 0.3);
    if (cu > 0 && cu < 1) {
      const k = Math.sin(Math.PI * cu);
      puff(p, C, 0, -3, 7 * (0.6 + 0.4 * k), k);
      puff(p, C, -4, 2, 5 * k, k);
      puff(p, C, 4, 1, 5 * k, k);
    }
    // a quick swirl streak (enter) or a pop flash (exit)
    if (enter) {
      const su = seg(t, 0.02, 0.3);
      if (su > 0 && su < 1) for (let j = 0; j < 2; j++) {
        const a0 = su * 5 + j * Math.PI, rr = 10 + 4 * su;
        for (let i = 0; i < 8; i++) {
          const a = a0 - i * 0.12;
          p.dot(Math.cos(a) * rr, Math.sin(a) * rr * SY - 2, i < 2 ? WHITE : C[3], (1 - su) * (1 - i / 8));
        }
      }
    } else if (t < 0.08) {
      p.circle(0, -2, 3 + 4 * (t / 0.08), C[3], 1 - t / 0.08);
    }
    // leftover wisps at the feet (enter ends in the loop's state)
    if (enter) {
      const k = smooth(0.35, 0.7, t);
      if (k > 0) wisps(p, C, S, t, k);
    }
    // a few glints
    for (let i = 0; i < 3; i++) {
      const r = rng(S + 90 + (enter ? 0 : 7), i), t0 = r.range(0.1, dur * 0.6), u = (t - t0) / 0.2;
      if (u < 0 || u > 1) continue;
      sparkle(p, r.range(-12, 12), r.range(-14, 6), 2.5 * Math.sin(Math.PI * u), C[3], WHITE, 0.4);
    }
    return;
  }
  wisps(p, C, S, t, 1);
}

// the loop: wisps creeping round the feet, slowly turning, and a faint glint now and then (seamless over D)
function wisps(p, C, S, t, k) {
  const ph = t / D;
  for (let i = 0; i < 6; i++) {
    const r = rng(S + 200, i), a = (ph + i / 6) * TAU * (i % 2 ? 1 : -1) * 0.5 + r.range(0, TAU);
    const rr = r.range(6, 11), breathe = 0.5 + 0.5 * Math.sin((ph * 2 + i / 6) * TAU);
    const x = Math.cos(a) * rr, y = FEET + Math.sin(a) * rr * SY * 0.6 - 1;
    puff(p, C, x, y, 2.2 + 1.2 * breathe, k * (0.35 + 0.35 * breathe));
  }
  for (let i = 0; i < 2; i++) {
    const r = rng(S + 300, i), t0 = r.next(), u = ((ph - t0) % 1 + 1) % 1 / 0.25;
    if (u > 1) continue;
    sparkle(p, r.range(-9, 9), r.range(-12, 2) - 4 * u, 2 * Math.sin(Math.PI * u), C[2], C[3], 0.25 * k);
  }
}

// the veil: mist rises from the ground round the body and swirls slowly while the character wavers away;
// it thickens as the body fades (about 0.3-0.7 s) and thins out by 1.2 s. Kept off the body's middle.
function veil(p, C, S, t, layer) {
  const items = [];
  for (let i = 0; i < 18; i++) {
    const r = rng(S + 400, i), a0 = (i / 18) * TAU + r.range(-0.15, 0.15), st = r.range(0, 0.35), life = r.range(0.7, 0.95);
    const u = (t - st) / life;
    if (u < 0 || u > 1) continue;
    const a = a0 + 1.4 * u * (i % 3 === 0 ? -1 : 1) * 0.6 + 1.2 * u;      // slow swirl
    const rr = r.range(8, 12) + 3 * u, rise = r.range(2, 9) * ease.outCubic(u);
    const x = Math.cos(a) * rr, y = FEET - 2 + Math.sin(a) * rr * SY - rise;
    const k = Math.min(1, u * 4) * (1 - smooth(0.55, 1, u)) * 0.85;
    const back = Math.sin(a) < 0;
    if (layer === "back" && !back || layer === "front" && back) continue;
    items.push([y, x, r.range(3.2, 4.8) * (0.6 + 0.6 * u), k]);
  }
  items.sort((a, b) => a[0] - b[0]);
  for (const [y, x, size, k] of items) puff(p, C, x, y, size, k);
  // thin swirl threads
  const su = seg(t, 0.05, 0.9);
  if (su > 0 && su < 1) for (let j = 0; j < 2; j++) {
    const a0 = su * 4.5 + j * Math.PI, rr = 12 + 2 * su;
    for (let i = 0; i < 10; i++) {
      const a = a0 - i * 0.12;
      if ((layer === "back") !== (Math.sin(a) < 0) && layer !== "all") continue;
      p.dot(Math.cos(a) * rr, FEET - 6 + Math.sin(a) * rr * SY - 4 * su, i < 2 ? C[3] : C[2], Math.sin(Math.PI * su) * (1 - i / 10) * 0.9);
    }
  }
}
