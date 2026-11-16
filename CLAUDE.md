# Build Godot game from a description

- Keep durable project status in `README.md`: what is built, what is left, and an asset table.
- Do not generate assets. Use the existing assets in this project (`content/`, `audio/`, `theme/`, `system/`).
- Read `godot-gdscript.md` for engine guidance: stack, project layout, and how to run.
- This is an existing project with hand-made scenes (`world.tscn`, `test.tscn`, etc.). Edit existing scenes in place; do not regenerate them with builder scripts. Builder scripts are only for new scenes.

## Delivery

Judge progress from the running game, never from a clean build: verify the structural things yourself (it loads, no errors, assets present) and let what you see drive the next iteration.

Decide from how the task is framed how to work. A task that invites collaboration — open-ended, exploratory, phrased as a direction rather than a spec — gets the live game early: checkpoint at decisions of taste, scope, or cost, and build freely in between. A task handed over as a finished brief to execute gets reasonable calls and steady progress, no blocking. Either way the result is proven, not claimed — do not record videos (ffmpeg is not installed); verify headless (no `SCRIPT ERROR` in the log), then ask the user to run the game (`godot --path .` or the editor) and confirm before you call the work done.
