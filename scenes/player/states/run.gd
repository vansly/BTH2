extends PlayerState

func _enter() -> void:
	obj.change_animation("run")

func _update(_delta: float) -> void:
	if control_jump(_delta):
		return
	if not control_moving(_delta):
		change_state(fsm.states.idle)
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
	
