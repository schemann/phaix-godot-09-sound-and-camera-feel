extends Camera3D
## What the camera adds to the walk, for the eye only: the view dips a little at every step (head bob).
## It moves this camera inside the head and nothing else. The player's body, its collider and its head (the yaw and the
## pitch that steer the walk) never see it, so the effect cannot change where the player goes.
## The bob follows the footsteps: the view is lowest when a foot comes down and highest halfway to the next step.

const Feel := preload("feel.gd")
const Footsteps := preload("footsteps.gd")
const FEEL: Feel = preload("feel.tres")

@export var footsteps: Footsteps ## Where the step cycle comes from.
@export var head_bob := true ## Off: the camera stays exactly where the head is. Head bob makes some players sick, so it can be turned off.

var _bob := 0.0 ## 0 standing, 1 walking, eased in between so the bob fades in and out.

func _process(delta: float) -> void:
	if not head_bob:
		_bob = 0.0
		position = Vector3.ZERO
		return
	var target := 1.0 if footsteps.walking else 0.0
	_bob += (target - _bob) * (1.0 - exp(-FEEL.bob_smoothing * delta)) # the same fade at any frame rate
	var cycle := footsteps.distance / FEEL.stride # 0 as a foot comes down, 1 at the next one
	position = Vector3(0.0, -FEEL.bob_height * _bob * (1.0 + cos(TAU * cycle)) / 2.0, 0.0)
