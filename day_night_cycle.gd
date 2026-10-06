extends DirectionalLight3D
class_name DayNightCycle

#just in case anh/chị đang tự hỏi, đúng, script này copy từ 1 cái addon. Nhưng, chẳng phải cái quan trọng là chúng ta biết mình đã học được  gì sao?

@export var day_light_energy: float = 1.0
@export var night_light_energy: float = 0.1

@export var day_star_intensity: float = 0.0
@export var night_star_intensity: float = 0.5

@export var current_time: float = 480 #in minutes, 480 = 8am
@export var speed_multiplier: float = 1.0
@export var seconds_per_minute: float = 1.0 #how many seconds in real life = 1 minute in game. 1.0 means a day in game is 24 minutes long

@export var day_length_hours: int = 24 #how many hours in a day
@export var day_length_minutes: int = 0 #addition in minutes to the day length

@export var sunrise_hour: int = 6 #at what hour does the sun rise
@export var sunset_hour: int = 18 #at what hour does the sun set (both in 24 hour format)

@export var night_light: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export var transition_speed: float = 0.06 #how much of a color/light transition happens per game minute (0.06 = the addon's 0.001 at default speed)

@export_subgroup("Sky")
@export var sunriseColor := Color("ffa052")
@export var dayColor := Color("037dff")
@export var sunsetColor := Color("ffa052")
@export var nightColor := Color("000214")
@export var daySunScatter := Color("4c4c4c")
@export var nightSunScatter := Color("0e0929")


@export var rotation_offset: Vector3

var sky: ShaderMaterial

var day_light_duration: float
var total_game_minutes: float
var my_rotation: float

var hours: int
var minutes: int

var currentColor: Color
var colorToLerp: Color

func _ready():
	sky = world_environment.environment.sky.sky_material

	total_game_minutes = day_length_hours * 60.0 + day_length_minutes
	day_light_duration = (sunset_hour - sunrise_hour) * 60.0
	my_rotation = 180.0 / day_light_duration

	update_clock()

	if hours == sunrise_hour:
		currentColor = sunriseColor
	elif hours > sunrise_hour && hours < sunset_hour:
		currentColor = dayColor
	elif hours == sunset_hour:
		currentColor = sunsetColor
	elif (hours > sunset_hour && hours <= day_length_hours) || (hours >= 0 && hours < sunrise_hour):
		currentColor = nightColor
	colorToLerp = currentColor

	if hours >= sunrise_hour && hours <= sunset_hour:
		light_energy = day_light_energy
		night_light.light_energy = 0.0 #turn off night light

		sky.set_shader_parameter("stars_intensity", day_star_intensity)
		sky.set_shader_parameter("sun_scatter", daySunScatter)
	else:
		light_energy = 0.0
		night_light.light_energy = night_light_energy

		sky.set_shader_parameter("stars_intensity", night_star_intensity)
		sky.set_shader_parameter("sun_scatter", nightSunScatter)


func _physics_process(delta: float) -> void:
	var minutes_passed: float = delta / seconds_per_minute * speed_multiplier
	current_time += minutes_passed

	if current_time >= total_game_minutes:
		current_time = 0.0

	var time_since_sunrise = current_time - sunrise_hour * 60.0

	rotation_degrees = Vector3(time_since_sunrise * my_rotation + 180.0, 0.0, 0.0) + rotation_offset

	update_clock()

	if hours == sunrise_hour:
		currentColor = sunriseColor
	elif hours == sunrise_hour + 1:
		currentColor = dayColor
	elif hours == sunset_hour - 1:
		currentColor = sunsetColor
	elif hours == sunset_hour:
		currentColor = nightColor

	#lerp weight must stay between 0 and 1, above 1 it overshoots and can blow up to NaN
	var lerp_speed: float = clamp(transition_speed * minutes_passed, 0.0, 1.0)
	colorToLerp = colorToLerp.lerp(currentColor, lerp_speed)
	sky.set_shader_parameter("top_color", colorToLerp)
	sky.set_shader_parameter("bottom_color", colorToLerp)

	if hours >= sunrise_hour && hours <= sunset_hour - 1:
		light_energy = lerp(light_energy, day_light_energy, lerp_speed)
		night_light.light_energy = lerp(night_light.light_energy, 0.0, lerp_speed)

		sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), day_star_intensity, lerp_speed))

		var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")

		var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
		sky.set_shader_parameter("sun_scatter", sunLerp.lerp(daySunScatter, lerp_speed))
	else:
		light_energy = lerp(light_energy, 0.0, lerp_speed)
		night_light.light_energy = lerp(night_light.light_energy, night_light_energy, lerp_speed)

		sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), night_star_intensity, lerp_speed))

		var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")

		var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
		sky.set_shader_parameter("sun_scatter", sunLerp.lerp(nightSunScatter, lerp_speed))

func update_clock():
	hours = int(current_time / 60)
	minutes = int(current_time) % 60
