extends CharacterBody2D

signal response_ready(text: String)
signal player_nearby(is_near: bool)

enum State { SITTING, ACTIVE }

const SPEED = 40.0
const INTERACT_RANGE = 80.0
const WANDER_BOUNDS := Rect2(380, 290, 160, 20)
const IDLE_TIME_MIN = 2.0
const IDLE_TIME_MAX = 5.0

var _state := State.SITTING
var _target := Vector2.ZERO
var _idle_timer := 0.0
var _is_idling := true
var _player_is_near := false
var _player: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	_check_player_distance()

	if _state == State.SITTING:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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

func _check_player_distance() -> void:
	if not _player:
		return
	var dist := global_position.distance_to(_player.global_position)
	var is_near := dist <= INTERACT_RANGE
	if is_near and not _player_is_near:
		_player_is_near = true
		if _state == State.SITTING:
			_state = State.ACTIVE
			_is_idling = true
			_idle_timer = randf_range(1.0, 2.0)
		emit_signal("player_nearby", true)
	elif not is_near and _player_is_near:
		_player_is_near = false
		emit_signal("player_nearby", false)

func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(WANDER_BOUNDS.position.x, WANDER_BOUNDS.end.x),
		randf_range(WANDER_BOUNDS.position.y, WANDER_BOUNDS.end.y)
	)

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
