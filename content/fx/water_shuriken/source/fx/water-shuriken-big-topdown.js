// The big, charged water shuriken: the same star as water-shuriken-topdown, drawn larger.
import { meta as small, draw as drawSmall } from "./water-shuriken-topdown.js";
export { drawSmall as draw };
export const meta = {
  ...small,
  name: "Water shuriken, big (top-down)",
  desc: "The charged water shuriken: a big spinning four-bladed star of water flying right, seen from above, flinging more droplets. Loops.",
  size: [80, 48],
  origin: [54, 24],
  options: { ...small.options, radius: 13, speed: 170, seed: 7 },
};
