extends CharacterBody2D

signal response_ready(text: String)
signal player_nearby(is_near: bool)

const SPEED = 40.0
const WANDER_BOUNDS := Rect2(330, 255, 300, 55)
const IDLE_TIME_MIN = 2.0
const IDLE_TIME_MAX = 5.0

var _target := Vector2.ZERO
var _idle_timer := 0.0
var _is_idling := true
var _player_is_near := false

func _ready() -> void:
	_pick_new_target()
	$InteractZone.body_entered.connect(_on_interact_zone_body_entered)
	$InteractZone.body_exited.connect(_on_interact_zone_body_exited)

func _physics_process(delta: float) -> void:
	if _is_idling:
		_idle_timer -= delta
		if _idle_timer <= 0:
			_is_idling = false
			_pick_new_target()
		velocity = Vector2.ZERO
	else:
		var dir := (_target - global_position)
		if dir.length() < 8.0:
			_is_idling = true
			_idle_timer = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)
			velocity = Vector2.ZERO
		else:
			velocity = dir.normalized() * SPEED

	move_and_slide()

func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(WANDER_BOUNDS.position.x, WANDER_BOUNDS.end.x),
		randf_range(WANDER_BOUNDS.position.y, WANDER_BOUNDS.end.y)
	)

func _on_interact_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_is_near = true
		emit_signal("player_nearby", true)

func _on_interact_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_is_near = false
		emit_signal("player_nearby", false)

func respond(message: String) -> void:
	var msg := message.strip_edges().to_lower()
	var reply: String

	if "สวัสดี" in message or "hello" in msg or "hi" in msg:
		reply = "...สวัสดี"
	elif "ทำอะไร" in message or "อยู่ไหน" in message:
		reply = "เดินเล่นอยู่"
	elif "ชื่อ" in message or "who are you" in msg:
		reply = "LinuxOS"
	elif "กินข้าว" in message or "หิว" in message:
		reply = "...ฉันไม่กินข้าว"
	else:
		reply = "..."

	emit_signal("response_ready", reply)
