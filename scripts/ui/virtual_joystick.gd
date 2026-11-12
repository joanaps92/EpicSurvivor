extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

const BASE_RADIUS: float = 52.0
const MAX_KNOB_DISTANCE: float = 38.0
const DEADZONE: float = 6.0

var _active_pointer: int = -1
var _anchor: Vector2 = Vector2.ZERO
var _knob_position: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_pointer == -1 and _is_activation_point(event.position):
			_begin_pointer(event.index, event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _active_pointer:
			_end_pointer()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _active_pointer:
		_update_pointer(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _active_pointer == -1 and _is_activation_point(event.position):
			_begin_pointer(-2, event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _active_pointer == -2:
			_end_pointer()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _active_pointer == -2:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_pointer(event.position)
			get_viewport().set_input_as_handled()
		else:
			_end_pointer()


func _is_activation_point(point: Vector2) -> bool:
	var viewport_size := get_viewport_rect().size
	return point.x <= viewport_size.x * 0.62 and point.y >= viewport_size.y * 0.48


func _begin_pointer(pointer_id: int, point: Vector2) -> void:
	_active_pointer = pointer_id
	var viewport_size := get_viewport_rect().size
	_anchor = Vector2(
		clampf(point.x, BASE_RADIUS, viewport_size.x - BASE_RADIUS),
		clampf(point.y, BASE_RADIUS + 24.0, viewport_size.y - BASE_RADIUS - 32.0)
	)
	_knob_position = _anchor
	_set_direction(Vector2.ZERO)
	queue_redraw()


func _update_pointer(point: Vector2) -> void:
	var offset := (point - _anchor).limit_length(MAX_KNOB_DISTANCE)
	_knob_position = _anchor + offset
	if offset.length() <= DEADZONE:
		_set_direction(Vector2.ZERO)
	else:
		_set_direction(offset / MAX_KNOB_DISTANCE)
	queue_redraw()


func _end_pointer() -> void:
	_active_pointer = -1
	_anchor = Vector2.ZERO
	_knob_position = Vector2.ZERO
	_set_direction(Vector2.ZERO)
	queue_redraw()


func _set_direction(value: Vector2) -> void:
	direction_changed.emit(value.limit_length(1.0))


func _draw() -> void:
	if _active_pointer == -1:
		return
	draw_circle(_anchor, BASE_RADIUS, Color(0.04, 0.08, 0.07, 0.50))
	draw_arc(_anchor, BASE_RADIUS, 0.0, TAU, 48, Color(0.82, 0.88, 0.72, 0.70), 2.0)
	draw_circle(_knob_position, 19.0, Color(0.78, 0.84, 0.66, 0.82))
