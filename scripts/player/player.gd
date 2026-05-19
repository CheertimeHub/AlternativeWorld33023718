extends CharacterBody2D

const SPEED_WALK = 80.0
const SPEED_RUN = 160.0

var _last_dir := Vector2.DOWN
var _walk_time := 0.0
var _idle_time := 0.0
var _is_moving := false

@onready var leg_l: ColorRect = $LegL
@onready var leg_r: ColorRect = $LegR
@onready var visual: Node2D = $Visual

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	var running := Input.is_action_pressed("ui_accept")
	var speed := SPEED_RUN if running else SPEED_WALK

	if direction != Vector2.ZERO:
		_last_dir = direction
		_is_moving = true
		_idle_time = 0.0
		velocity = direction.normalized() * speed
		_walk_time += delta * (18.0 if running else 10.0)
	else:
		_is_moving = false
		velocity = Vector2.ZERO
		_walk_time = 0.0
		_idle_time += delta

	_animate()
	move_and_slide()

func _animate() -> void:
	if _is_moving:
		var swing = sin(_walk_time) * 4.0
		leg_l.position.y = 4 + swing
		leg_r.position.y = 4 - swing
		visual.position.y = 0.0
	else:
		leg_l.position.y = 4.0
		leg_r.position.y = 4.0
		visual.position.y = sin(_idle_time * 1.2) * 1.0
