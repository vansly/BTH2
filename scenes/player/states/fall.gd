extends PlayerState

@onready var coyote_timer: Timer = $CoyoteTimer

func _enter() -> void:
	obj.change_animation("fall")
	if fsm.previous_state == fsm.states["idle"] or fsm.previous_state == fsm.states["run"]:
		coyote_timer.start(obj.coyote_time)


func _update(_delta: float) -> void:
	if control_wall_jump():
		return
	if control_wall_climb():
		return
	var is_moving = control_moving(_delta)
	if obj.jump_left > 0:
		if control_jump(_delta):
			coyote_timer.stop()
	if obj.is_on_floor() and not is_moving:
		change_state(fsm.states.idle)

func coyote_time_up() -> void:
	obj.jump_left -= 1

func _on_coyote_timer_timeout() -> void:
	print("Warning: Coyote time is up!")
	coyote_time_up()

func _exit() -> void:
	coyote_timer.stop()
