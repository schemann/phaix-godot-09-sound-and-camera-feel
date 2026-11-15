# Sound and Camera Feel in Godot 4

Project files for tutorial 09 of the Godot 4 series by Phaix on YouTube (https://www.youtube.com/@Phaix).

Give the generated rooms of a game like Roblox DOORS a sound and a feel in Godot 4.
We add door sounds on audio buses, footsteps that follow the distance you walk, a head bob, a field of view kick when a door opens and comfort settings the player can change and save.

The sounds are CC0 recordings from the RPG Audio pack by Kenney: every move of a door gets an AudioStreamPlayer3D on the SFX bus and the key's pick-up sound belongs to the player. A footstep comes every stride along the floor, not from a timer, through an AudioStreamRandomizer. The head bob dips the camera only, with an exponential fade, and the kick is a tween on the field of view. Both effects have an off switch, and the settings box saves them as JSON. Every step is its own project folder.

![Screenshot](screenshot.png)

## Steps

Every step of the video is its own folder in `steps/`, the exact state at the end of that
part. Open the project in Godot 4.7, then open `steps/<step>/main.tscn` and press F6 to run
that step. The project's main scene is the final step.

| Folder | Part of the video |
|---|---|
| `steps/step_00_start` | Starting point (the final state of tutorial 08) |
| `steps/step_01_door_sounds` | Step 1 - Door sounds on buses |
| `steps/step_02_footsteps` | Step 2 - Footsteps by distance |
| `steps/step_03_head_bob` | Step 3 - Head bob |
| `steps/step_04_fov_kick` | Step 4 - A field of view kick |
| `steps/step_05_comfort_settings` | Step 5 - Comfort settings |

## Controls

- W A S D or the arrow keys walk, and so does the left stick of a gamepad.
- The mouse or the right stick looks around.
- Space or the A button jumps.
- Esc gives the mouse back, and a left click captures it again.
- Hold Shift, or hold the left stick pressed in, to walk slowly.
- V or the left shoulder button shows your body from a second camera above the door, and V again gives the view back.
- Tab or the Back button shows and hides the map.
- R or the Y button starts the run again on the same seed.
- N or the right shoulder button starts a run on the next seed.
- T opens the seed box: type a seed and press Enter to start a run with it, or press Esc to close the box and change nothing. While the box is open, every other key you press goes into it.
- C or the X button copies the seed to the clipboard.
- F3 shows and hides the gizmos: the box of every planned room and its markers, drawn through the walls.
- F4 lifts the camera above the rooms to watch the generator, Enter plans the next room while you watch, and F4 again gives the view back.
- O or the Start button opens the settings. In them, the arrow keys, the d-pad or the left stick move between the rows, left and right change a volume, Enter or Space turns an effect on or off, and O, Start or Esc closes them.
- The settings come in `step_05_comfort_settings`.

## Tests

```sh
godot --headless --path . -s res://tests/run_tests.gd
```

## Support

Support the channel: https://ko-fi.com/phaix or https://github.com/sponsors/schemann

## License

Code and scenes: MIT (see LICENSE).
The figure and its animations: Animated Characters Protagonists by Kenney (www.kenney.nl), CC0, see character/License.txt.
The sounds (footsteps, doors, lock, key): RPG Audio by Kenney (www.kenney.nl, https://kenney.nl/assets/rpg-audio), CC0, see sounds/CREDITS.md.
