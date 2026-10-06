extends PlayerState

# Handles both wall climb (holding the key toward the wall) and wall cling (no key: slow slide down)

func _enter() -> void:
	obj.change_animation("run")
	obj.is_wall_clinging = true

func _update(_delta: float) -> void:
	if control_wall_jump():
		return
	if obj.is_on_floor():
		change_state(fsm.states.idle)
		return
	# Climbed past the top of the wall or got pushed off it
	if not obj.is_on_wall():
		change_state(fsm.states.jump if obj.velocity.y > 0 else fsm.states.fall)
		return

	var wall_normal: Vector3 = obj.get_wall_normal()
	var wall_input := get_wall_input(wall_normal)
	if wall_input == WallInput.OTHER or not obj.has_stamina():
		change_state(fsm.states.fall)
		return

	# Face the wall
	var into_wall = -wall_normal
	obj.change_direction(BaseCharacter.direction_from_input(Vector2(into_wall.x, into_wall.z)))

	var target_speed: float
	if wall_input == WallInput.TOWARD_WALL:
		target_speed = obj.wall_climb_speed
		obj.use_stamina(obj.wall_climb_stamina_cost * _delta)
	else:
		target_speed = -obj.wall_slide_speed
		obj.use_stamina(obj.wall_cling_stamina_cost * _delta)
	obj.velocity.y = move_toward(obj.velocity.y, target_speed, obj.wall_cling_gravity * _delta)

	# Keep pressing into the wall so is_on_wall() stays true next frame
	var stick = Vector3(into_wall.x, 0.0, into_wall.z).normalized() * obj.wall_stick_speed
	obj.velocity.x = stick.x
	obj.velocity.z = stick.z

func _exit() -> void:
	obj.is_wall_clinging = false
