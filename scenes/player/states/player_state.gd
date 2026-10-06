class_name PlayerState
extends FSMState

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	pass

#Control moving and changing state to run
#Return true if moving
func control_moving(delta: float) -> bool:
	var input: Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input.x, 0.0, input.y).normalized()

	var target_velocity = direction * obj.get_move_speed()

	var horizontal_velocity = Vector3(obj.velocity.x, 0.0, obj.velocity.z)

	var is_moving: bool = direction != Vector3.ZERO

	if is_moving:
		obj.change_direction(BaseCharacter.direction_from_input(input))
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, obj.get_acceleration() * delta)
		if obj.is_on_floor():
			change_state(fsm.states.run)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, obj.get_deceleration() * delta)

	obj.velocity.x = horizontal_velocity.x
	obj.velocity.z = horizontal_velocity.z
	return is_moving

#Wall jump when touching a wall in the air
#Return true if wall jumped
func control_wall_jump() -> bool:
	if Input.is_action_just_pressed("jump") and obj.is_on_wall_only():
		obj.wall_jump_normal = obj.get_wall_normal()
		change_state(fsm.states.walljump)
		return true
	return false

func control_jump(delta: float) -> bool:
	if Input.is_action_just_pressed("jump") and obj.can_jump():
		obj.jump_left -= 1
		obj.jump()
		change_state(fsm.states.jump)
		return true
	return false

#Grab the wall when touching it in the air
#Return true if grabbed
func control_wall_climb() -> bool:
	if not obj.is_on_wall_only() or not obj.has_stamina():
		return false
	# Pressing a key that isn't toward the wall means the player wants to leave it:
	# grabbing anyway would bounce between WallClimb and Fall every frame
	if get_wall_input(obj.get_wall_normal()) == WallInput.OTHER:
		return false
	change_state(fsm.states.wallclimb)
	return true

enum WallInput { NONE, TOWARD_WALL, OTHER }

#Classify the movement input relative to the wall the player is on
func get_wall_input(wall_normal: Vector3) -> WallInput:
	var input: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input == Vector2.ZERO:
		return WallInput.NONE
	var direction = Vector3(input.x, 0.0, input.y).normalized()
	var into_wall = -Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
	# ~45 degree cone around the direction into the wall
	if direction.dot(into_wall) > 0.7:
		return WallInput.TOWARD_WALL
	return WallInput.OTHER
