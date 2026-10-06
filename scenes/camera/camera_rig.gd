class_name CameraRig
extends Node3D

## Camera that follows the character.

## The character to follow. Assign it in the Inspector (drag the Player node in).
@export var target: Node3D

## Convergence speed. Higher follows tighter, lower lags more and feels smoother.
@export_range(0.1, 30.0, 0.1) var horizontal_follow_speed := 8.0
@export_range(0.1, 30.0, 0.1) var vertical_follow_speed := 8.0

## The camera never drifts further than this many metres from the character vertically.
@export_range(0.0, 10.0, 0.05) var max_vertical_lag := 0.75

## Camera position relative to the rig, the point it aims at, and the field of view.
@export var camera_offset := Vector3(0.0, 30.0, 30.0)
@export var focus_offset := Vector3.ZERO
@export var camera_fov := 30.0

@onready var camera: Camera3D = $Camera3D

var _is_initialized := false


func _ready() -> void:
	camera.position = camera_offset
	camera.fov = camera_fov
	# look_at works out the pitch, so there is no Rotation to type in by hand
	camera.look_at(global_position + focus_offset)
	_snap_to_target()


## Follow on every DRAWN frame, not every physics tick: the camera is a visual concern, so
## running it in _process keeps it smooth at the display's refresh rate.
func _process(delta: float) -> void:
	_follow(delta)


## Snap the rig onto the character. Called at startup so the camera does not fly in from the origin.
func _snap_to_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position
	_is_initialized = true

func _follow(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not _is_initialized:
		_snap_to_target()
		return

	var target_position := target.global_position

	var horizontal_weight := 1.0 - exp(-horizontal_follow_speed * delta)
	global_position.x = lerpf(global_position.x, target_position.x, horizontal_weight)
	global_position.z = lerpf(global_position.z, target_position.z, horizontal_weight)

	var vertical_weight := 1.0 - exp(-vertical_follow_speed * delta)
	var smoothed_y := lerpf(global_position.y, target_position.y, vertical_weight)
	global_position.y = clampf(
			smoothed_y,
			target_position.y - max_vertical_lag,
			target_position.y + max_vertical_lag
	)
