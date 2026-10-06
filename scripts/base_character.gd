class_name BaseCharacter
extends CharacterBody3D

## Y rotation of the Direction node for each facing.
## A Node3D looks along -Z, and the topdown camera sits on +Z, so -Z is "up" on screen.
const DIRECTION_YAW: Dictionary = {
	"up": 0.0,
	"left": PI / 2,
	"down": PI,
	"right": -PI / 2,
}

## The opposite facing, used by turn_around().
const OPPOSITE_DIRECTION: Dictionary = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left",
}

@export var direction: String = "down"

#region On-Ground Moving
@export_category("On-Ground Moving")

@export var on_ground_move_speed: float = 5.0
@export var on_ground_run_speed: float = 8.0
@export var on_ground_time_to_peak: float = 0.5
@export var on_ground_time_to_stop: float = 0.5
#endregion

#region On-Air Moving
@export_category("On-Air Moving")
@export var on_air_move_speed: float = 2.0
@export var on_air_time_to_peak: float = 0.5
@export var on_air_time_to_stop: float = 0.5
#endregion

#region Jump Properties
@export_category("Jumping")
@export var jump_height: float = 2.0
@export var jump_time_to_peak: float = 0.5
@export var jump_time_to_descend: float = 0.3
@export var max_jumps: int = 2
@export var coyote_time: float = 0.1

@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@onready var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)) * -1.0
@onready var jump_left: int = max_jumps
#endregion

#region Wall-Clinging and Wall Jumping

@export_group("Wall-Clinging/Jumping")
## Horizontal speed pushed away from the wall
@export var wall_jump_push_speed: float = 6.0
## How long air control is disabled after a wall jump, so the push isn't cancelled
@export var wall_jump_lock_time: float = 0.15

## Upward speed while holding the key toward the wall
@export var wall_climb_speed: float = 3.0
## Max downward speed while clinging without holding the key toward the wall
@export var wall_slide_speed: float = 1.5
## How fast vertical speed changes toward the climb/slide speed, so hitting the wall mid-jump isn't a hard stop
@export var wall_cling_gravity: float = 30.0
## Small push into the wall each frame so move_and_slide keeps reporting the contact
@export var wall_stick_speed: float = 1.0

# Saved when the wall jump is triggered: the WallJump state enters a frame later,
# when the wall contact may already be gone
var wall_jump_normal: Vector3 = Vector3.ZERO
# Set by the WallClimb state: the state drives velocity.y itself, so gravity is off
var is_wall_clinging: bool = false
#endregion

#region Stamina
@export_category("Stamina")
@export var max_stamina: float = 100.0
## Stamina recovered per second while on the floor
@export var stamina_regen_rate: float = 50.0
## Stamina spent per second while clinging/sliding down a wall
@export var wall_cling_stamina_cost: float = 10.0
## Stamina spent per second while climbing up a wall
@export var wall_climb_stamina_cost: float = 30.0

@onready var stamina: float = max_stamina
#endregion


var fsm: FSM = null
var current_animation = null

@onready var sprite: Sprite3D = $Sprite3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _next_animation = null
var _next_direction: String = "down"
var _played_direction: String = ""

func _ready() -> void:
	_next_direction = direction
	on_ground_run_speed = on_ground_move_speed * 1.6 # demanded


func _physics_process(delta: float) -> void:
	_check_changed_animation()

	if fsm != null:
		fsm._update(delta)
	#add gravity
	_update_movement(delta)
	_check_changed_direction()


func _update_movement(delta: float) -> void:
	var gravity = _get_gravity()
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if is_on_floor():
		reset_jump_left()
		stamina = minf(stamina + stamina_regen_rate * delta, max_stamina)

# Pick the facing from the input vector: whichever axis is stronger wins
static func direction_from_input(input: Vector2) -> String:
	if absf(input.x) > absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"

func turn_around() -> void:
	if _next_direction != direction:
		return
	_next_direction = OPPOSITE_DIRECTION[direction]

func is_left() -> bool:
	return direction == "left"

func is_right() -> bool:
	return direction == "right"

func turn_left() -> void:
	_next_direction = "left"

func turn_right() -> void:
	_next_direction = "right"

func turn_up() -> void:
	_next_direction = "up"

func turn_down() -> void:
	_next_direction = "down"

func jump() -> void:
	velocity.y = jump_velocity

# Push straight away from the wall and jump up
func do_wall_jump() -> void:
	velocity = wall_jump_normal * wall_jump_push_speed
	velocity.y = jump_velocity

func _get_gravity() -> float:
	if is_wall_clinging:
		return 0.0
	return jump_gravity if velocity.y > 0.0 else fall_gravity

func use_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)

func has_stamina() -> bool:
	return stamina > 0.0

func get_move_speed() -> float:
	if is_on_floor():
		return on_ground_run_speed if Input.is_action_pressed("run") else on_ground_move_speed
	else:
		return on_air_move_speed

func get_acceleration() -> float:
	if is_on_floor():
		return get_move_speed() / on_ground_time_to_peak
	return on_air_move_speed / on_air_time_to_peak

func get_deceleration() -> float:
	if is_on_floor():
		return on_ground_move_speed / on_ground_time_to_stop
	return on_air_move_speed / on_air_time_to_stop

func stop_move() -> void:
	velocity = Vector3.ZERO

# Stop horizontal movement, keep the falling velocity
func stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func change_animation(new_animation: String) -> void:
	_next_animation = new_animation

func change_direction(new_direction: String) -> void:
	_next_direction = new_direction

# The actual animation name played on AnimationPlayer, e.g. "run" + "left" -> "run_left"
func get_animation_name() -> String:
	if current_animation == null:
		return ""
	return "%s_%s" % [current_animation, direction]

func _check_changed_animation() -> void:
	var need_play: bool = false
	if _next_animation != current_animation:
		current_animation = _next_animation
		need_play = true
	# Changing facing must replay the animation too: each facing is its own animation
	if direction != _played_direction:
		_played_direction = direction
		need_play = true
	if is_running():
		anim_player.speed_scale = move_toward( anim_player.speed_scale, 1.6, get_acceleration())
	else:
		anim_player.speed_scale = move_toward( anim_player.speed_scale, 1.0, get_deceleration())
	if need_play and anim_player != null and current_animation != null:
		anim_player.play(get_animation_name())

func _check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		_on_changed_direction()

func _on_changed_direction() -> void:
	pass

func reset_jump_left() -> void:
	
	jump_left = max_jumps

func can_jump() -> bool:
	return (jump_left > 0)

func is_running() -> bool:
	return Input.is_action_pressed("run") and is_on_floor()
