extends Resource
## How walking feels: the numbers of the footsteps. One data file (feel.tres), tuned in the inspector and never in code.
## Measured against the rooms and the player: the player walks 5 m a second, a room is 10 to 18 m long.

@export var stride := 1.7 ## Metres per step. At 5 m a second that is three steps a second, the pace of a jog: six steps cross a 10 m room.
@export_range(0.0, 1.0) var first_step := 0.5 ## At the start of a run the first step comes after this part of a stride (0.85 m, a sixth of a second).
