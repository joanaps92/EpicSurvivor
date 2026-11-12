extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 150.0

var _mobile_direction: Vector2 = Vector2.ZERO


func set_mobile_direction(direction: Vector2) -> void:
	_mobile_direction = direction.limit_length(1.0)


func _physics_process(_delta: float) -> void:
	var keyboard_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	var direction := keyboard_direction if not keyboard_direction.is_zero_approx() else _mobile_direction
	velocity = direction * move_speed
	move_and_slide()


func _draw() -> void:
	# Placeholder de lectura y escala; se sustituirá por arte pixel art.
	draw_rect(Rect2(-7.0, -7.0, 14.0, 15.0), Color("#315c8a"))
	draw_rect(Rect2(-5.0, -13.0, 10.0, 8.0), Color("#e7cda0"))
	draw_rect(Rect2(-7.0, -15.0, 14.0, 4.0), Color("#708ea8"))
	draw_rect(Rect2(-9.0, -9.0, 18.0, 3.0), Color("#aec2cc"))
	draw_rect(Rect2(-6.0, 8.0, 4.0, 5.0), Color("#d8d2bd"))
	draw_rect(Rect2(2.0, 8.0, 4.0, 5.0), Color("#d8d2bd"))
