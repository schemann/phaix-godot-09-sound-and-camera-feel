extends Resource
## How walking feels. The numbers are data: tuned in the inspector, never in code.

@export var stride := 1.7 ## Metres per step. At 5 m a second that is three steps a second, a jog.
@export_range(0.0, 1.0) var first_step := 0.5 ## The first step of a run comes after this part of a stride.
@export_range(0.0, 0.15) var bob_height := 0.08 ## Metres the view dips at every step. Down and up only.
@export var bob_smoothing := 8.0 ## How fast the bob fades in and out, per second.
