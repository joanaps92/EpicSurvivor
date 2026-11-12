extends Node2D

@onready var _player: PlayerController = $Player
@onready var _joystick: VirtualJoystick = $HUD/VirtualJoystick
@onready var _position_label: Label = $HUD/Position


func _ready() -> void:
	_joystick.direction_changed.connect(_player.set_mobile_direction)


func _process(_delta: float) -> void:
	_position_label.text = "Aldric  ·  %d, %d" % [
		roundi(_player.global_position.x),
		roundi(_player.global_position.y),
	]
