extends PlayerState

func _enter() -> void:
	obj.change_animation("jump")
	obj.do_wall_jump()
	timer = obj.wall_jump_lock_time

func _update(_delta: float) -> void:
	# No control_moving here: air control is locked so the push away from the wall isn't cancelled
	if update_timer(_delta):
		change_state(fsm.states.jump if obj.velocity.y > 0 else fsm.states.fall)
