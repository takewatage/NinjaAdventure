// The big shuriken's impact: the same splash as water-shuriken-impact-topdown, scaled up.
import { meta as small, draw } from "./water-shuriken-impact-topdown.js";
export { draw };
export const meta = {
  ...small,
  name: "Water shuriken impact, big (top-down)",
  desc: "The charged water shuriken bursting, seen from above: a bigger flash and X cut, a wide crown of droplets, rings spreading far and a large puddle.",
  size: [88, 88],
  origin: [44, 44],
  duration: 0.65,
  options: { ...small.options, radius: 16, seed: 11 },
};
