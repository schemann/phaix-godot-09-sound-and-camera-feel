extends SceneTree
## Headless tests for tutorial 09. From the repository root:
##   godot --headless --path godot/09-sound-and-camera-feel -s res://tests/run_tests.gd
## Prints PASS or FAIL per test and exits with 0 only if every test passed.
## `-- --only=text` runs the tests whose name contains the text (for example `-- --only=footsteps`).
##
## Saves: every level the tests load gets its own temporary save file and its own settings file (OS temp dir), so a test run
## never reads or writes the real best_times.json or settings.json.
## What the tests prove is what the narration and the README claim; the video shows the game (series rule 33), the figures
## are measured here and printed (the lines that start with spaces under a PASS).

const Autopilot := preload("res://tools/autopilot.gd")
const Chain := preload("res://steps/step_05_comfort_settings/room_chain.gd") ## The finished chain (every step plans the run of step 0).

const STEPS: Array[String] = [
	"step_00_start",
	"step_01_door_sounds",
	"step_02_footsteps",
	"step_03_head_bob",
	"step_04_fov_kick",
	"step_05_comfort_settings",
]
const FINAL_STEP := "step_05_comfort_settings"
const SOUND_STEP := "step_01_door_sounds" ## The first step with sounds and buses.
const FOOTSTEP_STEP := "step_02_footsteps"
const BOB_STEP := "step_03_head_bob"
const KICK_STEP := "step_04_fov_kick"

## What each step changes against the one before (file names under the step folder; .uid files do not count).
const CHANGES: Dictionary[String, Dictionary] = {
	"step_01_door_sounds": {changed = ["door.gd", "door.tscn", "level.gd", "player.tscn"], added = []},
	"step_02_footsteps": {changed = ["player.tscn"], added = ["feel.gd", "feel.tres", "footsteps.gd", "footsteps.tres"]},
	"step_03_head_bob": {changed = ["feel.gd", "feel.tres", "player.tscn"], added = ["camera_feel.gd"]},
	"step_04_fov_kick": {changed = ["camera_feel.gd", "feel.gd", "feel.tres", "level.gd"], added = []},
	"step_05_comfort_settings": {changed = ["main.tscn"], added = ["settings.gd", "settings_menu.gd"]},
}

## The actions of tutorial 08, and the one this tutorial adds.
const ACTIONS: Array[String] = [
	"move_forward", "move_back", "move_left", "move_right", "jump", "walk", "look_left", "look_right", "look_up", "look_down",
	"toggle_debug", "regenerate", "next_seed", "edit_seed", "copy_seed", "capture_mouse",
	"toggle_view", "toggle_gizmos", "toggle_watch", "step_generation", "open_settings",
]

const SOUND_FILES: Dictionary[String, String] = { ## The fourteen sounds of sounds/ and the SHA-256 of each: the pack's own files, copied unchanged (sounds/CREDITS.md).
	"door_close.ogg": "834d29c60a8a8bfb50b158cdb6b7dfa8f02812a408a1ee9703d038dfab0b1aeb",
	"door_open.ogg": "4ab93bab96522d8eb109ff96dc57cb6765deb02448fe14c10472084be5bb2a0b",
	"footstep_01.ogg": "6fe61ef1fc3bcf0e253bf2eb64759db6cb69e2fe452f4d88cc597ecf78a3d601",
	"footstep_02.ogg": "313472dba31fd0c855376069fa368bb5a198c27251cc8398ef464578b7047a4c",
	"footstep_03.ogg": "2d9575b7dead6e1217ca113991fc5229e9b6d998ea0726ebbb277e7398ab888f",
	"footstep_04.ogg": "a86756b9af9f370455ab47844239bb07fd1bee7a113068c91f0fcd9b72703fae",
	"footstep_05.ogg": "fd264d72a7cd622b82abde202f4ed09fa7de95d34c36473ee938ce66cdf39830",
	"footstep_06.ogg": "817957e1f95d97fd36870064c41673895575cde17bccb245f50364c86ed10198",
	"footstep_07.ogg": "6cabfe7ae95d227a84066c6e17014ac31cc7c89b14ef51d7877e98352d4a64fb",
	"footstep_08.ogg": "42924cdbf998d5b3db180a339fd74afc94c570d594a536687e337ef1bdfdb346",
	"footstep_09.ogg": "668f14dc1254d0d0f33025e9c7dbcdf2c2f00462ed0e07fb8f099c1d711c1337",
	"footstep_10.ogg": "9324ebb9b2c5bcd078dcb523c6518d38a9f34081069d511602c2efb14ce06ce2",
	"key_pickup.ogg": "4b857968d64f9ac9336a10ffac6694d7547e1f01566ad6857b30bc8db3ee6c32",
	"lock_click.ogg": "9851a69d0c613e13bceef08060ecc4148f098ef487927cbebe270d642398a3b3",
}
const SOUND_PACK_URL := "kenney.nl/assets/rpg-audio"
const CLOSE_THUD := 0.2 ## Seconds into door_close.ogg where the thud is (the loudest point, measured from the file).
const WALK_SPEED := 5.0 ## Metres a second: player.gd's walk_speed.
const REST_FOV := 75.0 ## Degrees, vertical: the camera's default.
const WIDEST_FOV := 115.0 ## Degrees across a 16:9 screen: the widest view the kick may open (the end of its range gives 114.6).
const BOB_CEILING := 0.15 ## Metres: the deepest head bob feel.gd allows (the end of its range).
const BOB_HEIGHT := 0.08 ## Metres: the bob of the tutorial (the narration says eight centimetres).
const KICK_DEGREES := 5.0 ## Degrees the kick widens the view by.
const KICK_CEILING := 7.5 ## Degrees: the end of the range of kick_degrees.
const KICK_OUT := 0.12 ## Seconds.
const KICK_BACK := 0.45 ## Seconds.
const STEP_RATES: Array[int] = [30, 60, 144] ## Physics steps a second the footsteps rule is tried at.
const WALK_METRES := 20.0 ## The walk of the narration: 12 steps at every rate.
const WALK_STEPS := 12
const STATE_FINISHED := 2 ## Level.State
const SPEED_UP := 4 ## The full runs go this many times faster than real time.
const PLAN_SEEDS := 200 ## Seeds 1..200 for the comparisons between steps.
const SHORT_GOAL := 3 ## Goal room of the quick runs.
const KEY_ROOM := 1 ## The room with the key and the locked door in a test level (lock chance 1 locks it; room 0 is never locked).

## Counts the errors the engine logs. A test that hits a script error stops at that line and the engine hands back an
## empty array, which reads as a pass: `_report` charges the count to the test that ran.
class ScriptErrorCounter extends Logger:
	var count := 0
	var script_only := true ## false: warnings and errors of the engine count, too.
	var _lock := Mutex.new() ## The engine calls a logger from any thread.

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if script_only and error_type != ERROR_TYPE_SCRIPT:
			return
		_lock.lock()
		count += 1
		_lock.unlock()

## Calls its callback once per physics tick, before the player's own tick.
class Driver extends Node:
	signal finished
	var tick: Callable

	func _physics_process(_delta: float) -> void:
		if tick.is_valid() and tick.call():
			tick = Callable()
			finished.emit()

var _passed := 0
var _failed := 0
var _skipped := 0
var _script_errors := ScriptErrorCounter.new() ## Registered with the engine's logger for the whole run.
var _script_errors_reported := 0 ## How many script errors the tests reported so far have been charged with.
var _save_dir := ""
var _save_counter := 0

func _initialize() -> void:
	OS.add_logger(_script_errors)
	await process_frame
	var started := Time.get_ticks_msec()
	_save_dir = OS.get_temp_dir().path_join("phaix-godot-09-tests-%d" % OS.get_process_id()) # one folder per run: two runs at the same time must not wipe each other's save files
	_wipe_save_dir()

	await _run("code rules: no class_name, no global random, no wall clock, input only through named actions", test_code_rules)
	await _run("steps: each step changes only what its concept needs, everything else is copied forward", test_copy_forward)
	await _run("step_00_start: the final state of tutorial 08, file for file (only the folder names differ)", test_step_zero_is_tutorial_08)
	await _run("project: Jolt, the actions of tutorial 08, open_settings on O and the Start button, the main scene is the final step", test_project_settings)
	await _run("hud: step 0 to 4 say what tutorial 08 says; step 5 adds the O hint and the settings box; the Input Map is tutorial 08's plus open_settings", test_hud_and_input_map)
	await _run("plans: all six steps plan the run of step 0 (type, place, lock, key, props and lamp tint of seeds 1-%d): sound and camera move nothing" % PLAN_SEEDS, test_steps_plan_the_same)
	await _run("sounds: sounds/ holds the fourteen files of Kenney's RPG Audio pack, byte for byte, with CREDITS.md naming pack, licence and source; no generated sound, no room tone", test_sounds_are_kenneys)
	await _run("buses: the project's bus layout is Master and SFX, SFX sending to Master at 0 dB", test_buses)
	for step in STEPS:
		await _run("%s: the sound players: none in step 0; from step 1 the door's three and the key's pick-up sound; from step 2 the footsteps; none on Master, none that plays by itself" % step, test_sound_players.bind(step))
	for step: String in [SOUND_STEP, FINAL_STEP]: # door.gd and door.tscn are the same from step 1 on (test_copy_forward)
		await _run("%s: the door's sounds start with its move: opening and the lock on the frame, closing so that its thud lands as the swing ends, and a door opened again cancels it" % step, test_door_sounds_play.bind(step))
		await _run("%s: picking up a key plays its sound, and nothing else plays by itself (no room tone)" % step, test_key_pickup.bind(step))
	await _run("footsteps (step 2): a step every stride of the path walked, %d steps for %.0f m at %s physics steps a second; none standing or flying, the landing of a jump, no step for a bump or a restart" % [WALK_STEPS, WALK_METRES, STEP_RATES], test_footstep_rule)
	for step: String in [FOOTSTEP_STEP, FINAL_STEP]:
		await _run("%s: the player's footsteps: an Audio Stream Randomizer of ten steps, the same steps at 30, 60 and 120 physics steps a second, a jump lands once, a restart is silent" % step, test_footsteps_in_level.bind(step))
	for step: String in [BOB_STEP, FINAL_STEP]:
		await _run("%s: head bob: the view dips with the steps, at most the data's height, never up, sideways or tilted; fades in and out; off is exactly still" % step, test_head_bob.bind(step))
	for step: String in [KICK_STEP, FINAL_STEP]:
		await _run("%s: FOV kick: a door that opens widens the view fast and eases it back, never past %.0f degrees across 16:9; off is exactly still" % [step, WIDEST_FOV], test_fov_kick.bind(step))
	await _run("feel: one data file from step 2, the stride a jog's cadence, the bob and the kick inside the comfort limits", test_feel_data)
	await _run("feel: the same inputs give the same run with the effects on, off and in step 0 (seeds 42 and 1000, 900 ticks)", test_effects_change_no_movement)
	await _run("settings (step 5): saved like the best times: defaults, round trip, unknown keys kept, odd values, a damaged file kept as .bad, temp file and rename", test_settings_file)
	await _run("settings (step 5): O opens the box, the game waits; the arrows set the volumes on the buses and switch the effects at once; closing saves; a new game loads them", test_settings_menu)
	await _run("code rules: the footsteps, the camera and the settings only listen and play; player.gd is tutorial 08's; the level only plays the pick-up sound and kicks the camera", test_feel_code_rules)
	for step in STEPS:
		await _run("%s: a room stays until the door behind it has closed, nothing goes while it stands open" % step, test_rooms_wait_for_the_door.bind(step))
	await _run("full run: seed 42, goal room 20: the autopilot fetches every key and finishes, the footsteps keep step with the distance", test_full_run)
	await _run("restart: R while running leaves the body standing in room 0, in Move, at blend position 0", test_restart)
	for step in STEPS:
		await _run("%s: main scene runs 30 frames" % step, test_scene_runs.bind(step))

	_wipe_save_dir()
	OS.remove_logger(_script_errors)
	await create_timer(0.3).timeout # the audio server lets go of the stopped sounds in its own thread
	print("\n%d passed, %d failed, %d skipped in %.1f s" % [_passed, _failed, _skipped, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if _failed > 0 else 0)

#region Source rules

func test_code_rules() -> Array[String]:
	var failures: Array[String] = []
	var global_random := RegEx.create_from_string("(^|[^.\\w])(randi|randf|randi_range|randf_range|randomize|pick_random)\\(")
	var wall_clock := RegEx.create_from_string("(Time\\.get_|OS\\.get_ticks|OS\\.get_unix|OS\\.delay)")
	var scripts := _files_in("res://steps", ".gd")
	_expect(failures, scripts.size() >= 100, "found only %d scripts under steps" % scripts.size())
	for path in scripts:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line := lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			var where := "%s:%d" % [path.trim_prefix("res://"), i + 1]
			_expect(failures, not line.begins_with("class_name"), "%s: class_name" % where)
			_expect(failures, global_random.search(line) == null, "%s: global random call" % where)
			_expect(failures, wall_clock.search(line) == null, "%s: reads the wall clock" % where)
			_expect(failures, not line.contains("Input.is_key_pressed") and not line.contains("Input.is_physical_key_pressed"), "%s: reads a key directly" % where)
			_expect(failures, not line.contains("event is InputEventKey") and not line.contains("event is InputEventJoypad"), "%s: reads a key or button event directly" % where)
	return failures

## Every file of a folder and its sub folders that ends with the suffix.
func _files_in(dir_path: String, suffix: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	for sub in dir.get_directories():
		found.append_array(_files_in(dir_path.path_join(sub), suffix))
	for file in dir.get_files():
		if file.ends_with(suffix):
			found.append(dir_path.path_join(file))
	return found

func test_copy_forward() -> Array[String]:
	var failures: Array[String] = []
	for i in range(1, STEPS.size()):
		var before := STEPS[i - 1]
		var after := STEPS[i]
		var before_files := _step_files(before)
		var after_files := _step_files(after)
		var changed: Array[String] = []
		var added: Array[String] = []
		for file in before_files:
			if not after_files.has(file):
				failures.append("%s lost %s" % [after, file])
			elif _step_text(before, file) != _step_text(after, file):
				changed.append(file)
		for file in after_files:
			if not before_files.has(file):
				added.append(file)
		changed.sort()
		added.sort()
		var expected: Dictionary = CHANGES[after]
		var expected_changed: Array = expected.changed.duplicate()
		var expected_added: Array = expected.added.duplicate()
		expected_changed.sort()
		expected_added.sort()
		_expect(failures, changed == expected_changed, "%s changes %s, expected %s" % [after, changed, expected_changed])
		_expect(failures, added == expected_added, "%s adds %s, expected %s" % [after, added, expected_added])
	return failures

func _step_files(step: String) -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at("res://steps/" + step):
		if not file.ends_with(".uid"):
			files.append(file)
	if DirAccess.dir_exists_absolute("res://steps/%s/props" % step):
		for file in DirAccess.get_files_at("res://steps/%s/props" % step):
			if not file.ends_with(".uid"):
				files.append("props/" + file)
	return files

## The file's text with the step folder name blanked out, so copies compare equal.
func _step_text(step: String, file: String) -> String:
	return FileAccess.get_file_as_string("res://steps/%s/%s" % [step, file]).replace(step, "STEP")

## The folder of tutorial 08, which sits next to this project in the repository. Empty if it is not there.
func _tutorial_08() -> String:
	var folder := ProjectSettings.globalize_path("res://").path_join("../08-light-and-atmosphere").simplify_path()
	return folder if DirAccess.dir_exists_absolute(folder) else ""

## Step 0 is the last step of tutorial 08, copied. When that tutorial is not next to this project the test skips.
func test_step_zero_is_tutorial_08() -> Array[String]:
	var failures: Array[String] = []
	var tutorial := _tutorial_08()
	var original := tutorial.path_join("steps/step_05_global_illumination")
	if tutorial.is_empty() or not DirAccess.dir_exists_absolute(original):
		_skip("step_00_start equals the last step of tutorial 08", "tutorial 08 is not next to this project")
		return failures
	var original_files: Array[String] = []
	for file in DirAccess.get_files_at(original):
		if not file.ends_with(".uid"):
			original_files.append(file)
	for file in DirAccess.get_files_at(original.path_join("props")):
		if not file.ends_with(".uid"):
			original_files.append("props/" + file)
	_expect(failures, original_files.size() > 40, "found only %d files in the last step of tutorial 08" % original_files.size())
	for file in original_files:
		if not FileAccess.file_exists("res://steps/step_00_start/" + file):
			failures.append("step_00_start has no %s" % file)
			continue
		var theirs := _without_step_names(FileAccess.get_file_as_string(original.path_join(file))).replace("godot/08-light-and-atmosphere", "godot/PROJECT")
		var ours := _without_step_names(FileAccess.get_file_as_string("res://steps/step_00_start/" + file)).replace("godot/09-sound-and-camera-feel", "godot/PROJECT")
		_expect(failures, theirs == ours, "%s differs from the last step of tutorial 08" % file)
	_expect(failures, original_files.size() == _step_files("step_00_start").size(), "step_00_start has %d files, the last step of tutorial 08 has %d" % [_step_files("step_00_start").size(), original_files.size()])
	return failures

## The files of tutorial 08 point at one of its step folders, the copies here at the start folder.
func _without_step_names(text: String) -> String:
	return RegEx.create_from_string("step_\\d\\d_[a-z_]+").sub(text, "STEP", true)

func test_project_settings() -> Array[String]:
	var failures: Array[String] = []
	for action in ACTIONS:
		_expect(failures, ProjectSettings.has_setting("input/" + action), "no %s action" % action)
	_expect(failures, ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics", "the physics engine is not Jolt")
	_expect(failures, _physical_keys("toggle_gizmos") == ["F3"], "toggle_gizmos is %s, expected F3" % [_physical_keys("toggle_gizmos")])
	_expect(failures, _physical_keys("toggle_watch") == ["F4"], "toggle_watch is %s, expected F4" % [_physical_keys("toggle_watch")])
	_expect(failures, _physical_keys("open_settings") == ["O"], "open_settings has the keys %s, expected O" % [_physical_keys("open_settings")])
	var start := false
	for event in InputMap.action_get_events("open_settings"):
		start = start or (event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START)
	_expect(failures, start, "open_settings has no Start button")
	_expect(failures, ProjectSettings.get_setting("layer_names/3d_render/layer_3") == "Body", "render layer 3 is not named Body")
	_expect(failures, ProjectSettings.get_setting("application/run/main_scene") == "res://steps/%s/main.tscn" % FINAL_STEP, "the main scene is not the final step")
	return failures

## The text on the screen: steps 0 to 4 are tutorial 08's HUD; step 5 adds the O hint and the settings box and changes nothing else.
## The Input Map is tutorial 08's, plus the open_settings action.
func test_hud_and_input_map() -> Array[String]:
	var failures: Array[String] = []
	var reference := _hud_texts(STEPS[0])
	var hint := reference.get("Stats/DebugHint", "") as String
	_expect(failures, hint == "F3  gizmos      F4  watch it plan", "step 0 says '%s' as its debug hint" % hint)
	_expect(failures, reference.size() >= 10, "found only %d labels in the HUD of step 0" % reference.size())
	for step in STEPS:
		var texts := _hud_texts(step)
		for label_path: String in reference:
			_expect(failures, texts.get(label_path) == reference[label_path], "%s: %s says '%s' in the HUD scene, step 0 says '%s'" % [step, label_path, texts.get(label_path), reference[label_path]])
		var extra: Array[String] = []
		for label_path: String in texts:
			if not reference.has(label_path):
				extra.append(label_path)
		if step == FINAL_STEP:
			var settings_labels := extra.filter(func(label_path: String) -> bool: return label_path.begins_with("Settings/"))
			var others := extra.filter(func(label_path: String) -> bool: return not label_path.begins_with("Settings/"))
			_expect(failures, others == ["Stats/SettingsHint"] and texts.get("Stats/SettingsHint") == "O  settings", "%s: the HUD adds %s besides the settings box, expected only the hint 'O  settings'" % [step, others])
			_expect(failures, settings_labels.size() >= 4, "%s: the settings box has only %d labels" % [step, settings_labels.size()])
		else:
			_expect(failures, extra.is_empty(), "%s: the HUD scene has the labels %s that step 0 does not have" % [step, extra])
		var main := await _load_step(step, false)
		await _wait_physics(5)
		var label := main.get_node_or_null("HUD/Stats/DebugHint") as Label
		_expect(failures, label != null and label.text == hint, "%s: the hint on the screen says '%s', step 0 says '%s'" % [step, label.text if label != null else "no label", hint])
		await _unload(main)
	var tutorial := _tutorial_08()
	if tutorial.is_empty():
		_skip("hud: the Input Map is the one of tutorial 08 plus open_settings", "tutorial 08 is not next to this project")
		return failures
	var theirs := _input_section(tutorial.path_join("project.godot"))
	var ours := _without_action(_input_section(ProjectSettings.globalize_path("res://project.godot")), "open_settings")
	_expect(failures, theirs.length() > 1000, "found no [input] section in the project.godot of tutorial 08")
	_expect(failures, theirs == ours, "the [input] section of project.godot is not the one of tutorial 08 plus open_settings")
	return failures

## The text of every label of a step's HUD scene, by its path below the HUD.
func _hud_texts(step: String) -> Dictionary:
	var texts := {}
	var main := (load("res://steps/%s/main.tscn" % step) as PackedScene).instantiate()
	var hud := main.get_node("HUD")
	for label: Node in hud.find_children("*", "Label", true, false):
		texts[str(hud.get_path_to(label))] = (label as Label).text
	main.free()
	return texts

## Everything from the line "[input]" to the end of a project.godot.
func _input_section(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	var start := text.find("\n[input]")
	return text.substr(start) if start >= 0 else ""

## The [input] text without one action's block (from "name={" to the closing "}" line).
func _without_action(section: String, action: String) -> String:
	var kept: Array[String] = []
	var inside := false
	for line in section.split("\n"):
		if line.begins_with(action + "={"):
			inside = true
		elif inside and line == "}":
			inside = false
		elif not inside:
			kept.append(line)
	return "\n".join(kept)

#endregion

#region Chains (pure data, no scene)

## A chain of any step's script.
func _new_chain(chain_script: GDScript, chain_seed: int, goal_room: int, chance := 0.0) -> RefCounted:
	return chain_script.new(chain_seed, goal_room, chance)

## The room_chain.gd of a step.
func _chain_script(step: String) -> GDScript:
	return load("res://steps/%s/room_chain.gd" % step) as GDScript

## What the chain's Type enum calls the goal room.
func _goal_type(chain_script: GDScript) -> int:
	return (chain_script.get_script_constant_map()["Type"] as Dictionary)["GOAL"]

func _same_plans(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not _same_plan(a[i], b[i]):
			return false
	return true

## One plan against another: the room, its lock, its props and its lamp.
func _same_plan(a: Object, b: Object) -> bool:
	if a.index != b.index or a.type != b.type or a.transform != b.transform or a.bounds != b.bounds:
		return false
	return a.locked == b.locked and a.key_spot == b.key_spot and a.props == b.props and a.lamp == b.lamp

## All plans of a chain up to and including its goal room (at most `limit` plans).
func _plans_to_goal(chain_script: GDScript, chain_seed: int, goal_room: int, chance := 0.4, limit := 400) -> RefCounted:
	var chain := _new_chain(chain_script, chain_seed, goal_room, chance)
	while chain.plans.size() < limit:
		var plan: Object = chain.next_plan()
		if plan.type == _goal_type(chain_script):
			break
	return chain

## Every step plans the run of step 0 for every seed: sounds and camera effects never touch the generator.
func test_steps_plan_the_same() -> Array[String]:
	var failures: Array[String] = []
	var scripts: Array[GDScript] = []
	for step in STEPS:
		scripts.append(_chain_script(step))
	for chain_seed in range(1, PLAN_SEEDS + 1):
		if chain_seed % 20 == 0:
			await process_frame
		var base: Array = _plans_to_goal(scripts[0], chain_seed, 20).plans
		for i in range(1, scripts.size()):
			var other: Array = _plans_to_goal(scripts[i], chain_seed, 20).plans
			_expect(failures, _same_plans(base, other), "seed %d: %s plans another run than %s" % [chain_seed, STEPS[i], STEPS[0]])
		if failures.size() > 8:
			return failures
	return failures

#endregion

#region Walking the real player

## Runs tick once per physics tick until it returns true. (With Engine.time_scale above 1
## several ticks happen per frame, and `await physics_frame` would only see one of them.)
func _drive(tick: Callable) -> void:
	var driver := Driver.new()
	driver.process_priority = -100
	driver.tick = tick
	root.add_child(driver)
	await driver.finished
	root.remove_child(driver)
	driver.queue_free()

## Walks until the player is in room `goal`. dawdle: ticks of standing still at the start and at every new door.
func _walk(level: Node3D, pilot: RefCounted, goal: int, dawdle: int, on_tick: Callable) -> bool:
	var state := {"budget": 1500 * goal, "wait": dawdle, "target": pilot.door_index}
	await _drive(func() -> bool:
		if state["wait"] > 0:
			state["wait"] -= 1
		else:
			pilot.physics_step()
			if pilot.door_index != state["target"]:
				state["target"] = pilot.door_index
				state["wait"] = dawdle
				pilot.release()
		if on_tick.is_valid():
			on_tick.call()
		state["budget"] -= 1
		return level.current >= goal or state["budget"] <= 0)
	pilot.release()
	return level.current >= goal

#endregion

#region The sounds and the buses (steps 1 to 5)

func _from(step: String, first: String) -> bool:
	return STEPS.find(step) >= STEPS.find(first)

func _feel(step: String) -> Resource:
	return load("res://steps/%s/feel.tres" % step)

## A field of view across a 16:9 screen, from the vertical one the camera keeps.
func _across(vertical: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(vertical) / 2.0) * 16.0 / 9.0))

## Every AudioStreamPlayer and AudioStreamPlayer3D of a scene, by name.
func _players_in(scene_path: String) -> Dictionary:
	var found := {}
	var scene := (load(scene_path) as PackedScene).instantiate()
	for player: Node in scene.find_children("*", "AudioStreamPlayer", true, false) + scene.find_children("*", "AudioStreamPlayer3D", true, false):
		found[str(player.name)] = {"class": player.get_class(), "bus": str(player.get("bus")), "stream": player.get("stream"), "polyphony": player.get("max_polyphony"), "autoplay": player.get("autoplay"), "distance": player.get("max_distance"), "unit_size": player.get("unit_size"), "position": (player as Node3D).position if player is Node3D else Vector3.ZERO}
	scene.free()
	return found

func _stream_file(stream: Variant) -> String:
	return (stream as Resource).resource_path.get_file() if stream is Resource else ""

func _output_text(output: Array) -> String:
	var text := ""
	for chunk: Variant in output:
		text += str(chunk)
	return text

## sounds/ holds the recordings of Kenney's RPG Audio pack and nothing else: the files are the pack's own (their SHA-256 is
## pinned above), each one is a one-shot of under a second, there is no generated WAV and no room tone, and CREDITS.md names
## the author, the pack, the licence and the source.
func test_sounds_are_kenneys() -> Array[String]:
	var failures: Array[String] = []
	var shipped: Array[String] = []
	var others: Array[String] = []
	for file in DirAccess.get_files_at("res://sounds"):
		if file.ends_with(".import"):
			continue
		if file.ends_with(".ogg"):
			shipped.append(file)
		else:
			others.append(file)
	shipped.sort()
	var wanted: Array[String] = []
	wanted.assign(SOUND_FILES.keys())
	wanted.sort()
	_expect(failures, shipped == wanted, "sounds/ holds %s, expected %s" % [shipped, wanted])
	_expect(failures, others == ["CREDITS.md"], "sounds/ holds %s besides the sounds: only CREDITS.md belongs there (no generated WAV, no room tone)" % [others])
	var longest := 0.0
	for file in SOUND_FILES:
		_expect(failures, FileAccess.get_sha256("res://sounds/" + file) == SOUND_FILES[file], "%s is not the file of the pack (SHA-256 differs): the pack's files are copied unchanged" % file)
		var stream := load("res://sounds/" + file) as AudioStreamOggVorbis
		_expect(failures, stream != null and not stream.loop and stream.get_length() > 0.1 and stream.get_length() < 1.0, "%s is not a one-shot Ogg of under a second" % file)
		if stream != null:
			longest = maxf(longest, stream.get_length())
	var credits := FileAccess.get_file_as_string("res://sounds/CREDITS.md")
	for must: String in ["Kenney", "RPG Audio", "CC0", SOUND_PACK_URL, "creativecommons.org/publicdomain/zero/1.0"]:
		_expect(failures, credits.contains(must), "sounds/CREDITS.md does not say \"%s\"" % must)
	for file in SOUND_FILES: # the ten footsteps are listed as a range, footstep_01 to footstep_10
		if not file.begins_with("footstep_") or file in ["footstep_01.ogg", "footstep_10.ogg"]:
			_expect(failures, credits.contains(file.get_basename()), "sounds/CREDITS.md does not list %s" % file)
	_expect(failures, not FileAccess.file_exists("res://tools/sfx/make_sfx.py") and not FileAccess.file_exists("res://tools/seam_check.gd"), "a sound generator or the room tone's loop check is still in tools/: every sound is a recording")
	if failures.is_empty():
		print("        %d recordings of the pack, the longest %.2f s, all unchanged" % [SOUND_FILES.size(), longest])
	return failures

func test_buses() -> Array[String]:
	var failures: Array[String] = []
	_expect(failures, ProjectSettings.get_setting("audio/buses/default_bus_layout") == "res://default_bus_layout.tres" and FileAccess.file_exists("res://default_bus_layout.tres"), "the project has no default_bus_layout.tres")
	var names: Array[String] = []
	for bus in AudioServer.bus_count:
		names.append(AudioServer.get_bus_name(bus))
	_expect(failures, names == ["Master", "SFX"], "the buses are %s, expected Master, SFX" % [names])
	for bus in range(1, AudioServer.bus_count):
		_expect(failures, AudioServer.get_bus_send(bus) == &"Master" and AudioServer.get_bus_volume_db(bus) == 0.0 and AudioServer.get_bus_effect_count(bus) == 0, "%s: sends to %s at %.1f dB with %d effects" % [names[bus], AudioServer.get_bus_send(bus), AudioServer.get_bus_volume_db(bus), AudioServer.get_bus_effect_count(bus)])
	_expect(failures, AudioServer.get_bus_volume_db(0) == 0.0, "Master is at %.1f dB" % AudioServer.get_bus_volume_db(0))
	return failures

## The sound players each step has: none in step 0; from step 1 the door's three and the key's pick-up sound; from step 2
## the footsteps. Every one plays on SFX, never on Master itself, so its volume has a setting of its own, and none plays by itself.
## The door's three play one sound at a time, with a distance past which they are not mixed.
func test_sound_players(step: String) -> Array[String]:
	var failures: Array[String] = []
	var scenes := {}
	for file in DirAccess.get_files_at("res://steps/" + step):
		if file.ends_with(".tscn"):
			scenes[file.get_basename()] = _players_in("res://steps/%s/%s" % [step, file])
	var expected := {}
	if _from(step, SOUND_STEP):
		expected["door"] = {"OpenSound": ["AudioStreamPlayer3D", "SFX", "door_open.ogg"], "CloseSound": ["AudioStreamPlayer3D", "SFX", "door_close.ogg"], "LockSound": ["AudioStreamPlayer3D", "SFX", "lock_click.ogg"]}
		expected["player"] = {"KeyPickup": ["AudioStreamPlayer", "SFX", "key_pickup.ogg"]}
	if _from(step, FOOTSTEP_STEP):
		expected["player"]["Footsteps"] = ["AudioStreamPlayer3D", "SFX", "footsteps.tres"]
	_expect(failures, scenes.size() >= 10, "found only %d scenes in %s" % [scenes.size(), step])
	for scene: String in scenes:
		var have: Dictionary = scenes[scene]
		var want: Dictionary = expected.get(scene, {})
		var names: Array = have.keys()
		names.sort()
		var wanted: Array = want.keys()
		wanted.sort()
		_expect(failures, names == wanted, "%s: %s.tscn has the players %s, expected %s" % [step, scene, names, wanted])
		for player_name: String in have:
			var facts: Dictionary = have[player_name]
			_expect(failures, facts.bus != "Master" and facts.bus != "", "%s %s/%s plays on %s: nothing plays on Master itself" % [step, scene, player_name, facts.bus])
			var spec: Array = want.get(player_name, [])
			if spec.is_empty():
				continue
			_expect(failures, facts["class"] == spec[0] and facts.bus == spec[1] and _stream_file(facts.stream) == spec[2], "%s %s/%s: %s on %s playing %s, expected %s" % [step, scene, player_name, facts["class"], facts.bus, _stream_file(facts.stream), spec])
			_expect(failures, not facts.autoplay, "%s %s/%s: autoplay %s" % [step, scene, player_name, facts.autoplay])
			if scene == "door":
				_expect(failures, facts.unit_size == 3.0 and facts.distance == 30.0 and int(facts.polyphony) == 1, "%s %s: unit size %s, max distance %s, polyphony %s; the narration says 3, 30 and one sound at a time" % [step, player_name, facts.unit_size, facts.distance, facts.polyphony])
	if _from(step, FOOTSTEP_STEP):
		var feet: Dictionary = (scenes.player as Dictionary)["Footsteps"]
		_expect(failures, (feet.position as Vector3).y < 0.2 and int(feet.polyphony) == 2, "%s: the footsteps are not at the feet (%s) or cut each other off (polyphony %d)" % [step, feet.position, feet.polyphony])
	return failures

## Each move of the door has its sound: open and the lock start on the frame of the move, close waits so that its thud (CLOSE_THUD
## into the file) lands as the swing ends; a door opened again before that never plays the thud.
func test_door_sounds_play(step: String) -> Array[String]:
	var failures: Array[String] = []
	var main := await _load_step(step, true, {"goal_room": SHORT_GOAL})
	var level: Node3D = main.get_node("Level")
	var door: Node3D = level.rooms[0].door
	var open_sound := door.get_node("OpenSound") as AudioStreamPlayer3D
	var close_sound := door.get_node("CloseSound") as AudioStreamPlayer3D
	var lock_sound := door.get_node("LockSound") as AudioStreamPlayer3D
	_expect(failures, not open_sound.playing and not close_sound.playing and not lock_sound.playing, "%s: a door sound plays before the door moves" % step)
	door.open()
	_expect(failures, open_sound.playing and door.is_open and not close_sound.playing and not lock_sound.playing, "%s: the door opens without its sound, or with another one" % step)
	await _wait_physics(45)
	door.close()
	await _wait_physics(1)
	_expect(failures, not door.is_open and not close_sound.playing, "%s: the door swings back (open %s) and the close sound already plays: its thud would land before the frame" % [step, door.is_open])
	var wait := ceili((0.5 - CLOSE_THUD) * float(Engine.physics_ticks_per_second)) + 2 # the swing is 0.5 s
	await _wait_physics(wait)
	_expect(failures, close_sound.playing, "%s: the close sound does not play %.2f s into the swing back" % [step, float(wait + 1) / Engine.physics_ticks_per_second])
	await _wait_physics(60)
	# A door that opens again before the thud never plays it.
	close_sound.stop()
	door.open()
	await _wait_physics(45)
	door.close()
	await _wait_physics(3)
	door.open()
	await _wait_physics(wait + 10)
	_expect(failures, door.is_open and not close_sound.playing, "%s: a door opened again during the swing back still plays the close sound" % step)
	await _wait_physics(45)
	door.lock()
	door.rattle()
	_expect(failures, lock_sound.playing, "%s: the lock has no sound" % step)
	await _unload(main)
	return failures

## The key frees itself when it is touched; its sound is the player's and plays the moment the key counts. Nothing else plays by itself.
func test_key_pickup(step: String) -> Array[String]:
	var failures: Array[String] = []
	var main := await _load_with_key(step)
	var level: Node3D = main.get_node("Level")
	var room: Node3D = level.rooms[KEY_ROOM]
	var key := _keys_in(room)[0] if not _keys_in(room).is_empty() else null
	var pickup := level.player.get_node("KeyPickup") as AudioStreamPlayer
	_expect(failures, key != null and not pickup.playing, "%s: no key to pick up, or its sound already plays" % step)
	_expect(failures, pickup.get_parent() == level.player and key != null and key.find_children("*", "AudioStreamPlayer*", true, false).is_empty(), "%s: the pick-up sound is not the player's, or the key carries a sound that its pick-up would cut off" % step)
	if key != null:
		var picked := await _walk_into(level, room, key)
		_expect(failures, picked and level.keys == 1 and pickup.playing, "%s: the key was picked up (%s, keys %d) without its sound" % [step, picked, level.keys])
	var playing: Array[String] = []
	for node: Node in main.find_children("*", "AudioStreamPlayer*", true, false):
		if node != pickup and node.get("playing") and not (node.name in ["OpenSound", "CloseSound", "LockSound", "Footsteps"]):
			playing.append(str(node.name))
	_expect(failures, playing.is_empty(), "%s: %s plays by itself: the project has no room tone or other loop" % [step, playing])
	await _unload(main)
	return failures

#endregion

#region Footsteps by distance (step 2)

## A footsteps node on a body that stands still, its own physics step off: the test hands walk() the path.
func _lone_footsteps(step: String) -> Node:
	var body := CharacterBody3D.new()
	var feet := AudioStreamPlayer3D.new()
	feet.name = "Footsteps"
	feet.set_script(load("res://steps/%s/footsteps.gd" % step))
	body.add_child(feet)
	root.add_child(body)
	feet.set_physics_process(false)
	return feet

## Walks a path of straight legs (metres) at `rate` physics steps a second; returns where along the path each step fell.
func _steps_along(step: String, legs: Array[float], rate: int) -> Array[float]:
	var feet := _lone_footsteps(step)
	var per_step := WALK_SPEED / rate
	var walked := 0.0
	var fell: Array[float] = []
	for leg in legs:
		var left := leg
		while left > 0.0:
			var moved := minf(per_step, left)
			var before: int = feet.steps
			feet.walk(moved, true, 1.0 / rate)
			walked += moved
			left -= moved
			if feet.steps > before:
				fell.append(walked - float(feet.distance)) # the step fell `distance` metres before the end of this physics step
	feet.get_parent().free()
	return fell

func test_footstep_rule() -> Array[String]:
	var failures: Array[String] = []
	var feel := _feel(FINAL_STEP)
	var legs: Array[float] = [10.0, 3.3, 6.7] # a walk with two turns, 20.0 m
	var first: float = feel.stride * (1.0 - feel.first_step)
	var expected: Array[float] = []
	var at: float = first
	while at <= WALK_METRES:
		expected.append(at)
		at += feel.stride
	_expect(failures, expected.size() == WALK_STEPS, "the walk of %.0f m should have %d steps, the arithmetic gives %d" % [WALK_METRES, WALK_STEPS, expected.size()])
	var worst := 0.0
	for rate in STEP_RATES:
		var fell := _steps_along(FINAL_STEP, legs, rate)
		var same := fell.size() == expected.size()
		for i in mini(fell.size(), expected.size()):
			same = same and absf(fell[i] - expected[i]) < 0.0001
			worst = maxf(worst, absf(fell[i] - expected[i]))
		_expect(failures, same, "%d physics steps a second: %d steps at %s, expected %d at %s" % [rate, fell.size(), fell, expected.size(), expected])
	print("        a %.0f m walk: %d steps, the first after %.2f m, then every %.2f m, at %s physics steps a second, the worst place is off by %.6f m" % [WALK_METRES, expected.size(), first, feel.stride, STEP_RATES, worst])
	var feet := _lone_footsteps(FINAL_STEP)
	var dt := 1.0 / 60.0
	for i in 120:
		feet.walk(0.0, true, dt)
	_expect(failures, feet.steps == 0 and not feet.walking, "standing for 2 s made %d steps" % feet.steps)
	for i in 54: # a jump: 0.9 s in the air, moving
		feet.walk(0.08, false, dt)
	_expect(failures, feet.steps == 0, "a step in the air")
	feet.walk(0.08, true, dt)
	_expect(failures, feet.steps == 1 and is_zero_approx(feet.distance), "the landing made %d steps, distance %.2f" % [feet.steps, feet.distance])
	var before: float = feet.distance
	feet.walk(0.08, false, dt) # a bump at a seam: one physics step off the floor
	feet.walk(0.08, true, dt)
	_expect(failures, feet.steps == 1 and is_equal_approx(feet.distance, before + 0.08), "a bump of one physics step counted as a landing (%d steps, distance %.2f)" % [feet.steps, feet.distance])
	feet.walk(3.5, true, dt) # a restart puts the player back
	_expect(failures, feet.steps == 1 and is_equal_approx(feet.distance, first) and not feet.walking, "a teleport made a step or kept the walk (%d steps, distance %.2f)" % [feet.steps, feet.distance])
	feet.walk(1.0, true, dt) # one metre in one physics step is the edge: nobody walks that
	_expect(failures, feet.steps == 1, "a move of exactly 1 m in a physics step made a step")
	feet.get_parent().free()
	return failures

## The real player in a step: the same steps at 30, 60 and 120 physics steps a second, none standing, one landing, none at a restart.
func test_footsteps_in_level(step: String) -> Array[String]:
	var failures: Array[String] = []
	var feel := _feel(step)
	var randomizer := load("res://steps/%s/footsteps.tres" % step) as AudioStreamRandomizer
	_expect(failures, randomizer != null and randomizer.streams_count == 10 and randomizer.playback_mode == AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS, "%s: footsteps.tres is not a randomizer of ten steps that never repeats one" % step)
	if randomizer != null:
		for i in randomizer.streams_count:
			_expect(failures, _stream_file(randomizer.get_stream(i)) == "footstep_%02d.ogg" % (i + 1), "%s: footsteps.tres plays %s as its step %d" % [step, _stream_file(randomizer.get_stream(i)), i + 1])
		_expect(failures, is_equal_approx(randomizer.random_pitch, 1.06) and is_equal_approx(randomizer.random_volume_offset_db, 1.5), "%s: pitch %.2f, volume %.1f dB: the narration says 1.06 (about a semitone) and a little volume" % [step, randomizer.random_pitch, randomizer.random_volume_offset_db])
		_expect(failures, absf(pow(2.0, 1.0 / 12.0) - 1.06) < 0.002, "1.06 is not about a semitone")
	var counts: Array[int] = []
	var walked: Array[float] = []
	for rate: int in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		var main := await _load_step(step, true, {"goal_room": SHORT_GOAL})
		var level: Node3D = main.get_node("Level")
		var feet: Node = level.player.get_node("Footsteps")
		await _wait_physics(rate) # a second standing
		_expect(failures, feet.steps == 0, "%s at %d Hz: %d steps standing" % [step, rate, feet.steps])
		var from: Vector3 = level.player.global_position
		Input.action_press("move_forward")
		await _wait_physics(roundi(1.4 * rate))
		Input.action_release("move_forward")
		await _wait_physics(2)
		counts.append(feet.steps)
		walked.append(from.distance_to(level.player.global_position))
		if rate == 60:
			var landed: int = feet.steps
			Input.action_press("jump")
			await _wait_physics(2)
			Input.action_release("jump")
			await _wait_physics(80)
			_expect(failures, feet.steps == landed + 1, "%s: a jump in place made %d steps, expected 1 (the landing)" % [step, feet.steps - landed])
			var restarted: int = feet.steps
			await _key(KEY_R, 114)
			await _wait_physics(10)
			_expect(failures, feet.steps == restarted and is_equal_approx(feet.distance, feel.stride * (1.0 - feel.first_step)), "%s: the restart made a step or kept the old walk (%d steps, distance %.2f)" % [step, feet.steps - restarted, feet.distance])
		await _unload(main)
	Engine.physics_ticks_per_second = 60
	var expected := floori((walked[1] + feel.stride * (1.0 - feel.first_step)) / feel.stride)
	_expect(failures, counts == [expected, expected, expected], "%s: %s steps for %s m at 30, 60, 120 physics steps a second, expected %d each" % [step, counts, walked, expected])
	if failures.is_empty():
		print("        %s: %s steps over %.2f m of the real player at 30, 60 and 120 physics steps a second" % [step, counts, walked[1]])
	return failures

#endregion

#region Head bob (step 3) and field of view kick (step 4)

## Walks forward for `seconds`, sampling the camera every drawn frame.
func _sample_camera(level: Node3D, seconds: float, walk: bool) -> Dictionary:
	var camera := level.player.get_node("Head/Camera3D") as Camera3D
	var feet: Node = level.player.get_node("Footsteps")
	var head := level.player.get_node("Head") as Node3D
	var head_rest := head.transform
	var collider := level.player.get_node("CollisionShape3D") as CollisionShape3D
	var collider_rest := collider.transform
	var sample := {"low": 0.0, "high": 0.0, "side": 0.0, "turn": 0.0, "at_steps": [], "head_moved": false, "bobs": []}
	var stepped := [false]
	var on_step := func() -> void: stepped[0] = true
	feet.connect("stepped", on_step)
	if walk:
		Input.action_press("move_forward")
	var time := 0.0
	while time < seconds:
		await process_frame
		time += root.get_process_delta_time()
		sample.low = minf(sample.low, camera.position.y)
		sample.high = maxf(sample.high, camera.position.y)
		sample.side = maxf(sample.side, maxf(absf(camera.position.x), absf(camera.position.z)))
		sample.turn = maxf(sample.turn, camera.rotation.length())
		sample.head_moved = sample.head_moved or head.transform.origin != head_rest.origin or collider.transform != collider_rest
		(sample.bobs as Array).append(camera.get("_bob"))
		if stepped[0]:
			stepped[0] = false
			(sample.at_steps as Array).append(camera.position.y)
	Input.action_release("move_forward")
	feet.disconnect("stepped", on_step)
	return sample

func test_head_bob(step: String) -> Array[String]:
	var failures: Array[String] = []
	var feel := _feel(step)
	_expect(failures, is_equal_approx(feel.bob_height, BOB_HEIGHT) and feel.bob_height <= BOB_CEILING, "%s: bob_height is %.3f m, the narration says %.2f" % [step, feel.bob_height, BOB_HEIGHT])
	var main := await _load_step(step, true, {"goal_room": SHORT_GOAL})
	var level: Node3D = main.get_node("Level")
	var camera := level.player.get_node("Head/Camera3D") as Camera3D
	_expect(failures, camera.get("head_bob") == true and camera.position == Vector3.ZERO, "%s: the bob is off by default, or the camera is moved standing (%s)" % [step, camera.position])
	var walking := await _sample_camera(level, 2.0, true)
	_expect(failures, walking.low >= -feel.bob_height - 0.000001 and walking.high <= 0.000001, "%s: the view moved from %.4f to %.4f m: the bob dips at most %.3f m and never rises above the head" % [step, walking.low, walking.high, feel.bob_height])
	_expect(failures, walking.low <= -0.95 * feel.bob_height, "%s: the view dipped only %.4f m (the bob is %.3f m): it does not show" % [step, -walking.low, feel.bob_height])
	_expect(failures, is_zero_approx(walking.side) and is_zero_approx(walking.turn), "%s: the bob moves the camera sideways (%.4f m) or turns it (%.4f rad): no sway, no tilt" % [step, walking.side, walking.turn])
	_expect(failures, not walking.head_moved, "%s: the bob moved the head or the collider: only the camera moves" % step)
	var lows := (walking.at_steps as Array).filter(func(y: float) -> bool: return y <= -0.6 * feel.bob_height)
	_expect(failures, (walking.at_steps as Array).size() >= 3 and lows.size() >= (walking.at_steps as Array).size() - 1, "%s: the view is not low as the feet come down: %s" % [step, walking.at_steps])
	var bobs: Array = walking.bobs
	var rises := true
	for i in range(1, bobs.size()):
		rises = rises and bobs[i] >= bobs[i - 1]
	_expect(failures, rises and bobs[0] < 0.5 and bobs[-1] > 0.95, "%s: the bob does not fade in (first %.2f, last %.2f)" % [step, bobs[0], bobs[-1]])
	var stopping := await _sample_camera(level, 1.0, false) # standing
	var falls := true
	var stop_bobs: Array = stopping.bobs
	for i in range(3, stop_bobs.size()): # the first frames after the key goes up still see the last physics step's walk
		falls = falls and stop_bobs[i] <= stop_bobs[i - 1]
	_expect(failures, falls and stop_bobs[-1] < 0.01 and absf(camera.position.y) < 0.001, "%s: standing, the bob does not fade out (%.4f at the end, the view %.4f m down)" % [step, stop_bobs[-1], camera.position.y])
	camera.set("head_bob", false)
	var off := await _sample_camera(level, 1.4, true)
	_expect(failures, off.low == 0.0 and off.high == 0.0 and off.side == 0.0 and off.turn == 0.0 and camera.position == Vector3.ZERO, "%s: with the bob off the camera still moves (%.4f to %.4f m)" % [step, off.low, off.high])
	if failures.is_empty():
		print("        %s: the view dipped %.4f m at the most (bob_height %.2f m) over %d steps, never up, sideways or tilted; faded in to %.2f and out to %.3f" % [step, -walking.low, feel.bob_height, (walking.at_steps as Array).size(), bobs[-1], stop_bobs[-1]])
	await _unload(main)
	return failures

func test_fov_kick(step: String) -> Array[String]:
	var failures: Array[String] = []
	var feel := _feel(step)
	var main := await _load_step(step, true, {"goal_room": SHORT_GOAL})
	var level: Node3D = main.get_node("Level")
	var camera := level.player.get_node("Head/Camera3D") as Camera3D
	_expect(failures, camera.fov == REST_FOV and camera.get("fov_kick") == true, "%s: the camera rests at %.1f degrees, kick %s" % [step, camera.fov, camera.get("fov_kick")])
	_expect(failures, absf(_across(REST_FOV) - 107.5) < 0.05, "75 degrees high are %.2f across 16:9, the narration says 107.5" % _across(REST_FOV))
	var door: Node3D = level.rooms[0].door
	door.open() # the level hears the door and kicks the camera
	var peak_at := -1.0
	var back_at := -1.0
	var time := 0.0
	var high := camera.fov
	var low := camera.fov
	while time < feel.kick_out_time + feel.kick_back_time + 0.15:
		await process_frame
		time += root.get_process_delta_time()
		if camera.fov > high:
			high = camera.fov
			peak_at = time
		elif peak_at >= 0.0 and back_at < 0.0 and camera.fov == REST_FOV:
			back_at = time
		low = minf(low, camera.fov)
	_expect(failures, is_equal_approx(feel.kick_degrees, KICK_DEGREES) and is_equal_approx(feel.kick_out_time, KICK_OUT) and is_equal_approx(feel.kick_back_time, KICK_BACK), "%s: the kick is %.2f degrees, %.2f s out, %.2f s back; the narration says 2, 0.12 and 0.45" % [step, feel.kick_degrees, feel.kick_out_time, feel.kick_back_time])
	_expect(failures, low >= REST_FOV - 0.0001 and high <= REST_FOV + feel.kick_degrees + 0.0001, "%s: the view went from %.2f to %.2f degrees, the kick is %.1f" % [step, low, high, feel.kick_degrees])
	_expect(failures, high >= REST_FOV + feel.kick_degrees - 0.01 and peak_at <= feel.kick_out_time + 0.05, "%s: the kick reached %.2f degrees after %.2f s: it does not show, or it is slow" % [step, high, peak_at])
	_expect(failures, _across(high) <= WIDEST_FOV, "%s: at the kick's widest the view is %.1f degrees across 16:9, more than %.0f" % [step, _across(high), WIDEST_FOV])
	_expect(failures, camera.fov == REST_FOV and back_at > peak_at, "%s: the view is at %.3f degrees after the kick, not back at %.0f" % [step, camera.fov, REST_FOV])
	if failures.is_empty():
		print("        %s: the kick widened the view to %.2f degrees (%.1f across 16:9) after %.3f s and was back at exactly %.0f after %.3f s more" % [step, high, _across(high), peak_at, REST_FOV, back_at - peak_at])
	# Off in the middle of a kick: back to rest on the next frame. Off from the start: the view never changes.
	camera.call("kick")
	await process_frame
	await process_frame
	var mid := camera.fov
	camera.set("fov_kick", false)
	await process_frame
	_expect(failures, mid > REST_FOV and camera.fov == REST_FOV, "%s: turned off in the middle of a kick (at %.2f) the view stays at %.2f" % [step, mid, camera.fov])
	camera.call("kick")
	high = camera.fov
	time = 0.0
	while time < 0.8:
		await process_frame
		time += root.get_process_delta_time()
		high = maxf(high, camera.fov)
	_expect(failures, high == REST_FOV, "%s: with the kick off the view still widened to %.2f" % [step, high])
	await _unload(main)
	return failures

func test_feel_data() -> Array[String]:
	var failures: Array[String] = []
	for step in STEPS:
		var has := FileAccess.file_exists("res://steps/%s/feel.tres" % step)
		_expect(failures, has == _from(step, FOOTSTEP_STEP), "%s: feel.tres %s" % [step, "exists" if has else "is missing"])
		if not has:
			continue
		var feel := _feel(step)
		_expect(failures, (feel.get_script() as Script).resource_path == "res://steps/%s/feel.gd" % step, "%s: feel.tres is not a feel.gd Resource" % step)
		var cadence: float = WALK_SPEED / feel.stride
		_expect(failures, feel.stride == _feel(FOOTSTEP_STEP).stride and cadence >= 2.5 and cadence <= 3.5, "%s: a stride of %.2f m is %.1f steps a second at 5 m/s: a jog takes 2.5 to 3.5" % [step, feel.stride, cadence])
		_expect(failures, feel.first_step > 0.0 and feel.first_step <= 1.0, "%s: the first step after %.2f of a stride" % [step, feel.first_step])
		_expect(failures, (feel.get("bob_height") != null) == _from(step, BOB_STEP) and (feel.get("kick_degrees") != null) == _from(step, KICK_STEP), "%s: feel.gd has the bob %s and the kick %s" % [step, feel.get("bob_height") != null, feel.get("kick_degrees") != null])
		if _from(step, BOB_STEP):
			_expect(failures, feel.bob_height > 0.0 and feel.bob_height <= BOB_CEILING and feel.bob_smoothing > 0.0, "%s: the bob dips %.3f m (at most %.2f) and fades at %.1f a second" % [step, feel.bob_height, BOB_CEILING, feel.bob_smoothing])
			_expect(failures, _range_of(step, "bob_height") == [0.0, BOB_CEILING], "%s: the range of bob_height is %s, expected 0 to %.2f" % [step, _range_of(step, "bob_height"), BOB_CEILING])
		if _from(step, KICK_STEP):
			_expect(failures, feel.kick_degrees > 0.0 and _across(REST_FOV + feel.kick_degrees) <= WIDEST_FOV, "%s: a kick of %.1f degrees opens the view to %.1f across 16:9, at most %.0f" % [step, feel.kick_degrees, _across(REST_FOV + feel.kick_degrees), WIDEST_FOV])
			_expect(failures, feel.kick_out_time > 0.0 and feel.kick_out_time <= 0.2 and feel.kick_back_time > feel.kick_out_time and feel.kick_out_time + feel.kick_back_time <= 1.0, "%s: the kick takes %.2f s out and %.2f s back: fast out, slower back, under a second" % [step, feel.kick_out_time, feel.kick_back_time])
			var kick_range := _range_of(step, "kick_degrees")
			_expect(failures, kick_range == [0.0, KICK_CEILING] and _across(REST_FOV + KICK_CEILING) <= WIDEST_FOV, "%s: the range of kick_degrees is %s and ends at %.2f degrees across, the limit is %.0f" % [step, kick_range, _across(REST_FOV + KICK_CEILING), WIDEST_FOV])
	var walk_speed: float = (load("res://steps/%s/player.gd" % FINAL_STEP) as GDScript).get_property_default_value("walk_speed")
	_expect(failures, walk_speed == WALK_SPEED, "the player walks %.1f m a second, the feel is tuned for %.1f" % [walk_speed, WALK_SPEED])
	var final := _feel(FINAL_STEP)
	print("        stride %.2f m (%.2f steps a second at %.0f m/s), bob %.2f m (range ends at %.2f), kick %.1f degrees (%.2f to %.2f across 16:9, the range ends at %.3f across)" % [final.stride, WALK_SPEED / final.stride, WALK_SPEED, final.bob_height, BOB_CEILING, final.kick_degrees, _across(REST_FOV), _across(REST_FOV + final.kick_degrees), _across(REST_FOV + KICK_CEILING)])
	return failures

## The [min, max] of an exported range of feel.gd, from its property list.
func _range_of(step: String, property: String) -> Array:
	for info: Dictionary in (load("res://steps/%s/feel.gd" % step) as GDScript).get_script_property_list():
		if info.name == property:
			var parts := String(info.hint_string).split(",")
			return [float(parts[0]), float(parts[1])]
	return []

func _run_snapshot(level: Node3D) -> Array:
	return [level.state, level.current, level.keys, level.run_time, level.player.global_position, level.player.rotation, level.rooms.keys(), level.chain.plans.size(), level.seed_text]

## Everything the plans say, rejected rooms included.
func _plan_summary(plans: Array) -> Array:
	var summary: Array = []
	for plan: Object in plans:
		var rejected: Array = []
		var turned_down: Variant = plan.get("rejected")
		if turned_down != null:
			for r: Object in turned_down:
				rejected.append([r.type, r.reason, r.transform, r.bounds, r.hit])
		summary.append([plan.index, plan.type, plan.transform, plan.bounds, plan.locked, plan.key_spot, plan.props, plan.get("lamp"), rejected])
	return summary

## One run of a seed, `ticks` long, with the autopilot. effects: the camera's head bob and FOV kick (where the step has them).
func _feel_run(step: String, chain_seed: int, effects: bool, ticks: int) -> Dictionary:
	var main := await _load_step(step, true, {"goal_room": 8, "chain_seed": chain_seed})
	var level: Node3D = main.get_node("Level")
	var camera := level.player.get_node("Head/Camera3D") as Camera3D
	if camera.get("head_bob") != null:
		camera.set("head_bob", effects)
	if camera.get("fov_kick") != null:
		camera.set("fov_kick", effects)
	await _wait_physics(30)
	var pilot := Autopilot.new(level)
	var snapshots: Array = []
	var state := {"ticks": 0, "dip": 0.0, "widest": camera.fov}
	_fast_forward(true)
	await _drive(func() -> bool:
		pilot.physics_step()
		state["ticks"] += 1
		state["dip"] = maxf(state["dip"], -camera.position.y)
		state["widest"] = maxf(state["widest"], camera.fov)
		if state["ticks"] % 30 == 0:
			snapshots.append(_run_snapshot(level) + [(level.player.get_node("Head") as Node3D).transform])
		return state["ticks"] >= ticks or level.state == STATE_FINISHED)
	pilot.release()
	_fast_forward(false)
	snapshots.append(_run_snapshot(level) + [(level.player.get_node("Head") as Node3D).transform])
	var feet: Node = level.player.get_node_or_null("Footsteps")
	var result := {snapshots = snapshots, plans = _plan_summary(level.chain.plans), dip = state["dip"], widest = state["widest"], steps = feet.get("steps") if feet != null else 0}
	await _unload(main)
	return result

## The camera effects are for the eye only: the same inputs give the same run, tick for tick, with them on, with them off and in
## step 0, which has none (positions, rotations, the head, rooms, keys, time, plans).
func test_effects_change_no_movement() -> Array[String]:
	var failures: Array[String] = []
	for chain_seed: int in [42, 1000]:
		var start := await _feel_run(STEPS[0], chain_seed, false, 900)
		var on := await _feel_run(FINAL_STEP, chain_seed, true, 900)
		var off := await _feel_run(FINAL_STEP, chain_seed, false, 900)
		_expect(failures, on.dip > 0.01 and on.widest > REST_FOV + 1.0 and on.steps > 10, "seed %d: the effects did not run (dip %.3f m, widest %.2f degrees, %d steps): the comparison would prove nothing" % [chain_seed, on.dip, on.widest, on.steps])
		_expect(failures, off.dip == 0.0 and off.widest == REST_FOV, "seed %d: with the effects off the camera still moved (dip %.3f m, widest %.2f)" % [chain_seed, off.dip, off.widest])
		_expect(failures, on.snapshots == off.snapshots, "seed %d: the run differs with the effects on and off" % chain_seed)
		_expect(failures, on.snapshots == start.snapshots, "seed %d: the run of the finished step differs from step 0's" % chain_seed)
		_expect(failures, on.plans == off.plans and on.plans == start.plans, "seed %d: the plans differ" % chain_seed)
		print("        seed %d: %d snapshots equal on, off and in step 0 (dip %.3f m, widest %.2f degrees, %d steps), the player in room %d" % [chain_seed, on.snapshots.size(), on.dip, on.widest, on.steps, on.snapshots[-1][1]])
	return failures

#endregion

#region Comfort settings (step 5)

func _settings_script() -> GDScript:
	return load("res://steps/%s/settings.gd" % FINAL_STEP) as GDScript

func test_settings_file() -> Array[String]:
	var failures: Array[String] = []
	var Settings := _settings_script()
	# No file: the defaults, and loading writes nothing.
	var path := _fresh_settings_path()
	var settings: RefCounted = Settings.new(path)
	_expect(failures, settings.master_volume == 1.0 and settings.sfx_volume == 1.0 and settings.head_bob and settings.fov_kick, "the defaults are not full volume with both effects on")
	_expect(failures, not FileAccess.file_exists(path), "loading wrote a file")
	# A round trip, and the documented shape.
	settings.master_volume = 0.8
	settings.sfx_volume = 0.0
	settings.head_bob = false
	settings.save()
	var again: RefCounted = Settings.new(path)
	_expect(failures, again.master_volume == 0.8 and again.sfx_volume == 0.0 and not again.head_bob and again.fov_kick, "the saved settings do not load again")
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(failures, json is Dictionary and (json as Dictionary).get("formatVersion") == 1.0 and ((json as Dictionary).get("settings") as Dictionary).keys().size() == 4, "the file is not {formatVersion, settings: four values}: %s" % FileAccess.get_file_as_string(path))
	_expect(failures, not FileAccess.file_exists(path + ".tmp"), "the temp file is still there after the save")
	# Keys this version does not know survive a save.
	var future := _fresh_settings_path()
	_write_file(future, "{\"formatVersion\": 2, \"settings\": {\"masterVolume\": 0.5, \"subtitles\": true}, \"controls\": {\"invertY\": true}}")
	var kept: RefCounted = Settings.new(future)
	_expect(failures, kept.master_volume == 0.5, "a newer file's volume did not load")
	kept.save()
	var written: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(future))
	_expect(failures, written.get("formatVersion") == 2.0 and (written.get("settings") as Dictionary).get("subtitles") == true and (written.get("controls") as Dictionary).get("invertY") == true, "a save lost what a newer version wrote: %s" % written)
	# A value of the wrong kind is its default, a volume out of range is clamped.
	var odd := _fresh_settings_path()
	_write_file(odd, "{\"settings\": {\"masterVolume\": \"loud\", \"sfxVolume\": -1, \"headBob\": 0, \"fovKick\": \"no\"}}")
	var fixed: RefCounted = Settings.new(odd)
	_expect(failures, fixed.master_volume == 1.0 and fixed.sfx_volume == 0.0 and fixed.head_bob and fixed.fov_kick, "odd values: %s %s %s %s" % [fixed.master_volume, fixed.sfx_volume, fixed.head_bob, fixed.fov_kick])
	var loud := _fresh_settings_path()
	_write_file(loud, "{\"settings\": {\"masterVolume\": 3}}")
	_expect(failures, Settings.new(loud).master_volume == 1.0, "a volume of 3 is not clamped to 1")
	# A file that cannot be read is kept as .bad, the settings start from the defaults.
	var damaged := _fresh_settings_path()
	_write_file(damaged, "{\"settings\": {\"masterVolume\": 0.2")
	var rescued: RefCounted = Settings.new(damaged)
	_expect(failures, rescued.master_volume == 1.0 and FileAccess.file_exists(damaged + ".bad") and not FileAccess.file_exists(damaged), "a damaged file was not kept as .bad")
	# Writing into a folder that does not exist warns and goes on.
	var nowhere: RefCounted = Settings.new(_save_dir.path_join("missing/settings.json"))
	nowhere.save()
	var source := FileAccess.get_file_as_string("res://steps/%s/settings.gd" % FINAL_STEP)
	_expect(failures, source.contains("\".tmp\"") and source.contains("rename_absolute") and source.contains("flush()") and not source.contains("remove_absolute"), "settings.gd does not write a temp file, flush it and rename it, or it deletes a file")
	return failures

func test_settings_menu() -> Array[String]:
	var failures: Array[String] = []
	var path := _fresh_settings_path()
	var main := await _load_step(FINAL_STEP, true, {"goal_room": SHORT_GOAL, "settings_path": path})
	var level: Node3D = main.get_node("Level")
	var menu := main.get_node("HUD/Settings") as Control
	var camera := level.player.get_node("Head/Camera3D") as Camera3D
	var master := main.get_node("HUD/Settings/Rows/Master/Slider") as HSlider
	_expect(failures, (main.get_node("HUD/Stats/SettingsHint") as Label).text == "O  settings" and not menu.visible, "the HUD does not say O, or the box is up")
	await _key(KEY_O, 111)
	_expect(failures, menu.visible and level.typing and level.player.frozen and master.has_focus(), "O: box %s, the level waits %s, the player stands %s, the master volume has the focus %s" % [menu.visible, level.typing, level.player.frozen, master.has_focus()])
	var chain: RefCounted = level.chain
	await _key(KEY_R, 114) # the keys of the game do nothing while the box is up
	await _key(KEY_N, 110)
	_expect(failures, level.chain == chain and menu.visible, "R or N restarted the run behind the box")
	for i in 4:
		await _key(KEY_LEFT)
	_expect(failures, is_equal_approx(master.value, 0.8) and is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.8), "four presses of Left: the slider is at %.2f, Master at %.2f" % [master.value, AudioServer.get_bus_volume_linear(0)])
	await _key(KEY_DOWN)
	for i in 22:
		await _key(KEY_LEFT)
	var sfx := AudioServer.get_bus_index("SFX")
	_expect(failures, AudioServer.is_bus_mute(sfx) and AudioServer.get_bus_volume_linear(sfx) == 0.0 and (main.get_node("HUD/Settings/Rows/Sfx/Slider") as HSlider).value == 0.0, "the sounds at 0 do not mute the SFX bus")
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	_expect(failures, camera.get("head_bob") == false, "Enter on Head bob did not turn it off")
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	_expect(failures, camera.get("fov_kick") == false, "Enter on FOV kick did not turn it off")
	await _key(KEY_O, 111)
	_expect(failures, not menu.visible and not level.typing and not level.player.frozen, "O again: the box is still up or the player still waits")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var values: Dictionary = (saved as Dictionary).get("settings", {}) if saved is Dictionary else {}
	_expect(failures, is_equal_approx(float(values.get("masterVolume", -1.0)), 0.8) and values.get("sfxVolume") == 0.0 and values.get("headBob") == false and values.get("fovKick") == false and not values.has("ambienceVolume"), "closing saved %s" % values)
	await _unload(main)
	_expect(failures, AudioServer.get_bus_volume_linear(0) == 1.0 and not AudioServer.is_bus_mute(sfx), "the buses keep the game's volumes after the scene is gone (Master %.2f, SFX muted %s)" % [AudioServer.get_bus_volume_linear(0), AudioServer.is_bus_mute(sfx)])
	# A new game reads the file: the volumes on the buses, the effects on the camera, the box shows them.
	var again := await _load_step(FINAL_STEP, true, {"goal_room": SHORT_GOAL, "settings_path": path})
	var camera_again := (again.get_node("Level") as Node3D).get("player").get_node("Head/Camera3D") as Camera3D
	_expect(failures, is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.8) and AudioServer.is_bus_mute(sfx) and camera_again.get("head_bob") == false and camera_again.get("fov_kick") == false, "the saved settings are not in use in a new game")
	_expect(failures, is_equal_approx((again.get_node("HUD/Settings/Rows/Master/Slider") as HSlider).value, 0.8) and not (again.get_node("HUD/Settings/Rows/HeadBob") as CheckButton).button_pressed, "the box does not show the saved settings")
	# Esc closes the box too, and saves.
	await _key(KEY_O, 111)
	await _key(KEY_RIGHT)
	await _key(KEY_ESCAPE)
	_expect(failures, not (again.get_node("HUD/Settings") as Control).visible and is_equal_approx(float((JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary).settings.masterVolume), 0.85), "Esc did not close the box and save")
	await _unload(again)
	# The steps before have no settings: O does nothing.
	var before := await _load_step(KICK_STEP, true, {"goal_room": SHORT_GOAL})
	await _key(KEY_O, 111)
	_expect(failures, before.get_node_or_null("HUD/Settings") == null and not (before.get_node("Level") as Node3D).get("typing"), "O did something in step 4")
	await _unload(before)
	return failures

func _code_lines(path: String) -> Array[String]:
	var lines: Array[String] = []
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var code := line.split("##")[0].strip_edges()
		if not code.is_empty() and not code.begins_with("#"):
			lines.append(code)
	return lines

## The new code only listens and plays: the footsteps read where the player is, the camera moves itself and changes its own
## field of view, the settings set buses and two switches. None of it writes the player, the head, a plan or the run; player.gd
## is tutorial 08's in every step, and the level does no more than play the pick-up sound and kick the camera.
func test_feel_code_rules() -> Array[String]:
	var failures: Array[String] = []
	var writes := RegEx.create_from_string("\\b(body|player|head|level|owner|get_parent\\(\\))\\.[\\w.]+\\s*(=|\\+=|-=)[^=]")
	var forbidden := RegEx.create_from_string("\\b(velocity|move_and_slide|chain|plans?|seed\\w*|run_time|keys|_spawn_room|rotate_view)\\b")
	for step in STEPS:
		var files: Array[String] = []
		if _from(step, FOOTSTEP_STEP):
			files.append_array(["footsteps.gd", "feel.gd"])
		if _from(step, BOB_STEP):
			files.append("camera_feel.gd")
		if step == FINAL_STEP:
			files.append_array(["settings.gd", "settings_menu.gd"])
		for file in files:
			for line in _code_lines("res://steps/%s/%s" % [step, file]):
				_expect(failures, writes.search(line) == null and forbidden.search(line) == null, "%s/%s: %s" % [step, file, line])
		if _from(step, BOB_STEP):
			var assigned := RegEx.create_from_string("^\\s*([\\w.]+)\\s*(=|\\+=|-=)[^=]")
			for line in _code_lines("res://steps/%s/camera_feel.gd" % step):
				var found := assigned.search(line)
				if found != null and not line.strip_edges().begins_with("var "):
					_expect(failures, found.get_string(1) in ["position", "fov", "_bob", "_kick"], "%s/camera_feel.gd writes %s: the camera moves only itself" % [step, found.get_string(1)])
		_expect(failures, _step_text(step, "player.gd") == _step_text(STEPS[0], "player.gd").replace(STEPS[0], "STEP"), "%s/player.gd is not tutorial 08's: the effects must not touch the walk" % step)
	var start := FileAccess.get_file_as_string("res://steps/%s/level.gd" % STEPS[0]).split("\n")
	var added: Array[String] = []
	for line in FileAccess.get_file_as_string("res://steps/%s/level.gd" % FINAL_STEP).split("\n"):
		if not start.has(line) and not line.strip_edges().is_empty():
			added.append(line.strip_edges())
	var allowed: Array[String] = [
		"## The key is gone the moment it is touched, so its sound is the player's: a sound in the player's hands, not in the room.",
		"(player.get_node(\"KeyPickup\") as AudioStreamPlayer).play()",
		"const CameraFeel := preload(\"camera_feel.gd\")",
		"var camera: CameraFeel ## The player's camera: a door that opens kicks its field of view.",
		"camera = player.get_node(\"Head/Camera3D\") as CameraFeel",
		"camera.kick()",
		"## A door starts to open: kick the camera, build what is behind it. Only the newest room's door asks for",
	]
	for line in added:
		_expect(failures, allowed.has(line), "level.gd adds \"%s\": the level only plays the pick-up sound and kicks the camera" % line)
	_expect(failures, added.size() == allowed.size(), "level.gd adds %d lines, expected the %d of the pick-up sound and the kick" % [added.size(), allowed.size()])
	return failures

#endregion

#region The game underneath (tutorial 08's final state, with sound and camera around it)

## The keys lying in a room: children with a picked_up signal that are not on their way out.
func _keys_in(room: Node3D) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for child in room.get_children():
		if child.has_signal("picked_up") and not child.is_queued_for_deletion():
			found.append(child)
	return found

## A level with a key to fetch: lock_chance 1 locks every room but room 0 and the one before the goal, so room 1 is
## locked; the autopilot brings the player into it, the key still lies there.
func _load_with_key(step: String, extra := {}) -> Node:
	var settings := {"goal_room": 6, "lock_chance": 1.0}
	settings.merge(extra, true)
	var main := await _load_step(step, true, settings)
	var level: Node3D = main.get_node("Level")
	_fast_forward(true)
	var pilot := Autopilot.new(level)
	await _walk(level, pilot, KEY_ROOM, 0, Callable())
	_fast_forward(false)
	await _wait_physics(5)
	return main

## Walks the player at a key from 2.5 m away, from the side of the entrance (away from the door), until the key is gone.
func _walk_into(level: Node3D, room: Node3D, key: Node3D) -> bool:
	var player: CharacterBody3D = level.player
	var entrance := (room.get("entrance") as Marker3D).global_position
	var towards_entrance := Vector3(entrance.x - key.global_position.x, 0.0, entrance.z - key.global_position.z).normalized()
	player.global_position = key.global_position + towards_entrance * 2.5
	var direction := key.global_position - player.global_position
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.velocity = Vector3.ZERO
	await _wait_physics(3)
	return await _walk_forward_until(func() -> bool: return not is_instance_valid(key) or key.is_queued_for_deletion(), 180)

## Holds move_forward until the condition is true (checked once per physics frame) or the ticks run out.
func _walk_forward_until(condition: Callable, max_ticks: int) -> bool:
	Input.action_press("move_forward")
	var reached := false
	for i in max_ticks:
		await physics_frame
		if condition.call():
			reached = true
			break
	Input.action_release("move_forward")
	return reached

## Room 2 entered: the door of room 1 starts to close behind the player, room 0 is the oldest room.
func _door_closing_behind_room_2(step: String) -> Node:
	var main := await _load_step(step)
	var level: Node3D = main.get_node("Level")
	level.rooms[0].door.open() # builds room 1
	level._on_room_entered(level.player, 1)
	await _wait_physics(45)
	level.rooms[1].door.open() # builds room 2
	await _wait_physics(45)
	level._on_room_entered(level.player, 2)
	return main

## Through the door behind the player the picture goes along the room just left, to the doorway of the one before it.
func test_rooms_wait_for_the_door(step: String) -> Array[String]:
	var failures: Array[String] = []
	var main := await _door_closing_behind_room_2(step)
	var level: Node3D = main.get_node("Level")
	_expect(failures, level.rooms.has(0), "room 0 went while the door behind the player stood open")
	await _wait_physics(45)
	_expect(failures, not level.rooms.has(0), "room 0 is still there behind the shut door")
	_expect(failures, level.rooms.has(1), "the room just left went with room 0")
	_expect(failures, not level.rooms[1].get_node("Shell/WallEntrance/Opening").visible, "the room just left has no wall at its entrance")
	await _unload(main)
	main = await _door_closing_behind_room_2(step)
	level = main.get_node("Level")
	await _wait_physics(10)
	level.rooms[1].door.open() # the player turned around while the leaf still swings
	await _wait_physics(45)
	_expect(failures, level.rooms.has(0), "room 0 went while the door stood open again")
	level.start()
	if level.has_method("_on_door_closed"):
		level._on_door_closed(2) # a restart is faster than the door of the old run
		_expect(failures, level.rooms.has(0), "the door of the old run took room 0 of the new one")
	else:
		_expect(failures, false, "level.gd has no _on_door_closed")
	await _unload(main)
	return failures

func test_full_run() -> Array[String]:
	var failures: Array[String] = []
	var main := await _load_step(FINAL_STEP)
	var level: Node3D = main.get_node("Level")
	var feet: Node = level.player.get_node("Footsteps")
	var pilot := Autopilot.new(level)
	var walked := [0.0, level.player.global_position]
	_fast_forward(true)
	var budget := [60 * 60 * 5]
	await _drive(func() -> bool:
		pilot.physics_step()
		var here: Vector3 = level.player.global_position
		var last: Vector3 = walked[1]
		var moved := Vector2(here.x - last.x, here.z - last.z).length()
		if moved < 1.0: # a restart or a teleport is no walk
			walked[0] += moved
		walked[1] = here
		budget[0] -= 1
		return level.state == STATE_FINISHED or budget[0] <= 0)
	pilot.release()
	_fast_forward(false)
	_expect(failures, level.state == STATE_FINISHED, "the run did not finish (room %d, %.1f s)" % [level.current, level.run_time])
	_expect(failures, level.current == 20, "finished in room %d" % level.current)
	_expect(failures, level.run_time > 30.0 and level.run_time < 150.0, "the run took %.1f s" % level.run_time)
	var feel := _feel(FINAL_STEP)
	var expected := floori((float(walked[0]) + feel.stride * (1.0 - feel.first_step)) / feel.stride)
	_expect(failures, absi(feet.steps - expected) <= 12, "the run made %d footsteps over %.1f m, the stride says about %d (jumps add their landings)" % [feet.steps, walked[0], expected])
	_expect(failures, feet.steps > 40, "the run made only %d footsteps" % feet.steps)
	print("        full run, seed 42: %.2f s of game time, %.1f m along the floor, %d footsteps (the stride %.2f m says %d)" % [level.run_time, walked[0], feet.steps, feel.stride, expected])
	await _unload(main)
	return failures

func _state(player: CharacterBody3D) -> String:
	var tree := player.get_node("Body/AnimationTree") as AnimationTree
	return (tree.get("parameters/playback") as AnimationNodeStateMachinePlayback).get_current_node()

func test_restart() -> Array[String]:
	var failures: Array[String] = []
	var main := await _load_step(FINAL_STEP)
	var level: Node3D = main.get_node("Level")
	var player: CharacterBody3D = level.player
	var tree := player.get_node("Body/AnimationTree") as AnimationTree
	Input.action_press("move_forward")
	await _wait_physics(30)
	Input.action_release("move_forward")
	await _action("regenerate")
	await _wait_physics(40)
	_expect(failures, player.global_position.distance_to(Vector3(0.0, 0.0, 3.5)) < 0.05, "the player is at %s" % player.global_position)
	_expect(failures, _state(player) == "Move", "the tree is in %s" % _state(player))
	_expect(failures, is_zero_approx(tree.get("parameters/Move/blend_position")), "blend position %.2f" % tree.get("parameters/Move/blend_position"))
	await _unload(main)
	return failures

func test_scene_runs(step: String) -> Array[String]:
	var failures: Array[String] = []
	var main := await _load_step(step, false)
	for i in 30:
		await process_frame
	_expect(failures, is_instance_valid(main) and main.is_inside_tree(), "scene left the tree")
	await _unload(main)
	return failures

#endregion

#region Harness

func _run(test_name: String, test: Callable) -> void:
	if not _selected(test_name):
		return
	await process_frame # the engine empties its message queue between tests: the chain tests build thousands of room scenes
	var failures: Array[String] = await test.call()
	_report(test_name, failures)

func _selected(test_name: String) -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only=") and not test_name.contains(argument.trim_prefix("--only=")):
			return false
	return true

func _report(test_name: String, failures: Array[String]) -> void:
	var script_errors := _script_errors.count - _script_errors_reported
	_script_errors_reported = _script_errors.count
	if script_errors > 0: # the test stopped at the failing line and the engine returned an empty array, which would read as a pass
		failures.insert(0, "the test stopped with a script error: see the log")
	if failures.is_empty():
		_passed += 1
		print("PASS  ", test_name)
		return
	_failed += 1
	print("FAIL  ", test_name)
	for message: String in failures.slice(0, 8):
		print("        ", message)
	if failures.size() > 8:
		print("        ... and %d more" % (failures.size() - 8))

func _skip(test_name: String, reason: String) -> void:
	_skipped += 1
	print("SKIP  ", test_name)
	print("        ", reason)

func _expect(failures: Array[String], condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

## Instances a step's main scene. By default it waits until the CSG shapes have built their collision.
## props are set on the Level before it enters the tree (goal_room, seed_text, lock_chance ...; "chain_seed" is the
## text of the seed's digits). "settings_path" is the file of the settings box of step 5.
## Every level gets a fresh temporary save file unless props bring one, and so does the settings box.
func _load_step(step: String, settle := true, props := {}) -> Node:
	var scene: PackedScene = load("res://steps/%s/main.tscn" % step)
	var main := scene.instantiate()
	var level := main.get_node("Level")
	if not props.has("save_path"):
		level.set("save_path", _fresh_save_path())
	for key: String in props:
		if key == "settings_path":
			continue
		if key == "chain_seed":
			level.set("seed_text", str(props[key]))
		else:
			level.set(key, props[key])
	var menu := main.get_node_or_null("HUD/Settings")
	if menu != null: # step 5: the settings box reads and writes a file of its own
		menu.set("save_path", props.get("settings_path", _fresh_settings_path()))
	root.add_child(main)
	if settle:
		await _wait_physics(10)
	return main

func _unload(main: Node) -> void:
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "look_left", "look_right", "look_up", "look_down", "jump", "walk"]:
		Input.action_release(action)
	for sound: Node in main.find_children("*", "AudioStreamPlayer", true, false) + main.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.call("stop") # a sound that still plays when its player is freed is reported as leaked at exit (Godot issue 76745)
	root.remove_child(main)
	main.free()
	await process_frame

## A path in the temporary test folder that no file exists at.
func _fresh_save_path() -> String:
	_save_counter += 1
	DirAccess.make_dir_recursive_absolute(_save_dir)
	return _save_dir.path_join("best_times_%d.json" % _save_counter)

func _fresh_settings_path() -> String:
	_save_counter += 1
	DirAccess.make_dir_recursive_absolute(_save_dir)
	return _save_dir.path_join("settings_%d.json" % _save_counter)

func _write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _wipe_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_save_dir):
		return
	for file in DirAccess.get_files_at(_save_dir):
		DirAccess.remove_absolute(_save_dir.path_join(file))
	DirAccess.remove_absolute(_save_dir)

## Runs the simulation faster than real time with the same 1/60 s steps: the engine ticks
## SPEED_UP times as often and hands out SPEED_UP times the delta of each (smaller) tick.
func _fast_forward(on: bool) -> void:
	Engine.physics_ticks_per_second = 60 * (SPEED_UP if on else 1)
	Engine.time_scale = float(SPEED_UP) if on else 1.0

func _wait_physics(frames: int) -> void:
	for i in frames:
		await physics_frame

func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await process_frame

## Presses and releases a key like a player does: through the input system, so the control that has the focus gets it.
func _key(code: Key, unicode := 0) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
		await process_frame

## The names of an action's keyboard keys ("F3"), by physical key.
func _physical_keys(action: StringName) -> Array[String]:
	var keys: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(OS.get_keycode_string((event as InputEventKey).physical_keycode))
	return keys

#endregion
