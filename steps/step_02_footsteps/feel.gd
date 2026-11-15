extends Resource
## How walking feels. The numbers are data: tuned in the inspector, never in code.

@export var stride := 1.7 ## Metres per step. At 5 m a second that is three steps a second, a jog.
@export_range(0.0, 1.0) var first_step := 0.5 ## The first step of a run comes after this part of a stride.
