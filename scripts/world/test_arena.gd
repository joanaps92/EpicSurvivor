extends Node2D

const ARENA_HALF_SIZE: float = 2048.0
const GRID_STEP: int = 64
const PATCH_COUNT: int = 180


func _draw() -> void:
	draw_rect(
		Rect2(
			Vector2(-ARENA_HALF_SIZE, -ARENA_HALF_SIZE),
			Vector2(ARENA_HALF_SIZE * 2.0, ARENA_HALF_SIZE * 2.0)
		),
		Color("#36583e")
	)

	for coordinate in range(-int(ARENA_HALF_SIZE), int(ARENA_HALF_SIZE) + 1, GRID_STEP):
		draw_line(
			Vector2(coordinate, -ARENA_HALF_SIZE),
			Vector2(coordinate, ARENA_HALF_SIZE),
			Color(0.78, 0.85, 0.62, 0.08),
			1.0
		)
		draw_line(
			Vector2(-ARENA_HALF_SIZE, coordinate),
			Vector2(ARENA_HALF_SIZE, coordinate),
			Color(0.78, 0.85, 0.62, 0.08),
			1.0
		)

	var random := RandomNumberGenerator.new()
	random.seed = 4001
	for _index in PATCH_COUNT:
		var patch_position := Vector2(
			random.randf_range(-ARENA_HALF_SIZE, ARENA_HALF_SIZE),
			random.randf_range(-ARENA_HALF_SIZE, ARENA_HALF_SIZE)
		)
		var patch_size := Vector2(
			random.randi_range(8, 22),
			random.randi_range(6, 16)
		)
		draw_rect(
			Rect2(patch_position, patch_size),
			Color(0.68, 0.76, 0.47, 0.18)
		)
