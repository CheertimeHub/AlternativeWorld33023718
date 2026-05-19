extends CharacterBody2D

const SPEED_WALK = 80.0
const SPEED_RUN = 160.0

var sprite: AnimatedSprite2D = null
var _last_dir := Vector2.DOWN

func _ready() -> void:
	if has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	var running := Input.is_action_pressed("ui_accept")
	var speed := SPEED_RUN if running else SPEED_WALK
	var prefix := "run" if running else "walk"

	if direction != Vector2.ZERO:
		_last_dir = direction
		velocity = direction.normalized() * speed
		_play_anim(prefix, direction)
	else:
		velocity = Vector2.ZERO
		_play_anim("idle", _last_dir)

	move_and_slide()

func _play_anim(prefix: String, dir: Vector2) -> void:
	if not sprite:
		return
	if dir.y < 0:
		sprite.flip_h = dir.x < 0
		sprite.play(prefix + "_up")
	elif dir.y > 0 or dir == Vector2.ZERO:
		sprite.flip_h = false
		sprite.play(prefix + "_down")
	else:
		sprite.flip_h = dir.x < 0
		sprite.play(prefix + "_side")
