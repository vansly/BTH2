extends PlayerState

func _enter() -> void:
	obj.change_animation("jump")

func _update(_delta: float):
	if control_wall_jump():
		return
	if control_wall_climb():
		return
	control_moving(_delta)
	if obj.jump_left > 0:
		control_jump(_delta)
	if obj.velocity.y < 0:
		change_state(fsm.states.fall)
