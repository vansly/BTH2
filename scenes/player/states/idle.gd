extends PlayerState

func _enter() -> void:
	obj.change_animation("idle")

func _update(_delta: float) -> void:
	#Control jump
	if control_jump(_delta):
		return
	#Control moving
	control_moving(_delta)
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
