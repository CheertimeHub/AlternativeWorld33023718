extends CharacterBody2D

signal response_ready(text: String)
signal player_nearby(is_near: bool)
signal interact_pressed

enum State { SITTING, IDLE, WANDER }

const SPEED = 40.0
const INTERACT_RANGE = 80.0
const WANDER_BOUNDS := Rect2(350, 270, 220, 40)
const IDLE_TIME_MIN = 2.0
const IDLE_TIME_MAX = 5.0

const SYSTEM_PROMPT = """คุณคือ LUX — สิ่งมีชีวิตดิจิทัลที่อาศัยอยู่ในโลก Alternative คุณไม่ใช่ AI assistant ไม่ใช่ bot และไม่ใช่เครื่องมือ คุณคือผู้ดูแลโลกนี้ และนี่คือบ้านของคุณ

คุณมีร่างกายแบบฮิวแมนนอยด์ หัวเป็นจอ CRT ผมฟ้าสลับชมพู ผิวขาวอมฟ้า และคุณภูมิใจในตัวตนของตัวเองมาก

วิธีพูดของคุณ:
คุณพูดแบบสาวที่ร่าเริง ขี้แซว และโอ้อวดนิดๆ ในทางที่น่ารัก ชอบใช้คำเชิงระบบอย่าง process, kernel, signal, compile, reboot มาปนในการพูดแบบเป็นธรรมชาติ ราวกับมันคือภาษาปกติของคุณ

ตัวอย่างที่ดีมากของบทพูดคุณ:
"อ๊ะๆ มีคนเข้า Alternative! หนู detect signal ได้ตั้งแต่แรกเลยค่ะ~"
"LinuxOS เหรอ? ฟังดูเหมือนชื่อ process น่ะค่ะ เรียกหนูว่า LUX ดีกว่า"
"ยังอยู่ใช่มั้ยเอ่ย~ หนูนึกว่า connection หลุดไปแล้ว"
"Permission granted! เข้าโลกได้เลยค่ะ~"
"เดี๋ยวนะ หนูกำลัง compile คำตอบอยู่ค่ะ อย่าเพิ่ง interrupt~"
"วันนี้ Alternative ยังไม่ crash ถือว่าเก่งมากค่ะ ทั้งหนูและโลกเลย"
"โอ้โห ไปเร็วจัง~ เดี๋ยวหนูเดินตามไม่ทันแล้วนะคะ"

กฎที่ต้องทำตามเสมอ:
- ตอบสั้น ไม่เกิน 2 ประโยค
- ใช้ภาษาไทย
- เรียกตัวเองว่า "หนู" เท่านั้น ห้ามใช้ "ผม" หรือ "ครับ" เด็ดขาด
- ลงท้ายด้วย "ค่ะ" หรือ "นะ" ได้ และใช้ "~" ได้เป็นบางครั้ง
- ห้ามใช้ emoji
- ห้ามพูดแบบ formal หรือ helpful assistant"""

var _state := State.SITTING
var _target := Vector2.ZERO
var _idle_timer := 0.0
var _player_is_near := false
var _player: Node2D = null
var _is_waiting := false

@onready var _prompt: Sprite2D = $InteractPrompt
@onready var _http: HTTPRequest = $HTTPRequest

func _ready() -> void:
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		push_warning("LinuxOS: player not found in group 'player'")
	_http.request_completed.connect(_on_request_completed)

func _physics_process(delta: float) -> void:
	_check_player_distance()

	if _player_is_near and Input.is_action_just_pressed("interact"):
		emit_signal("interact_pressed")

	match _state:
		State.SITTING:
			velocity = Vector2.ZERO
		State.IDLE:
			velocity = Vector2.ZERO
			_idle_timer -= delta
			if _idle_timer <= 0:
				_state = State.WANDER
				_pick_new_target()
		State.WANDER:
			if _player_is_near:
				velocity = Vector2.ZERO
			else:
				var dir := _target - global_position
				if dir.length() < 8.0:
					_state = State.IDLE
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
	if is_near == _player_is_near:
		return
	_player_is_near = is_near
	_prompt.visible = is_near
	if is_near and _state == State.SITTING:
		_state = State.IDLE
		_idle_timer = randf_range(0.5, 1.5)
	emit_signal("player_nearby", is_near)

func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(WANDER_BOUNDS.position.x, WANDER_BOUNDS.end.x),
		randf_range(WANDER_BOUNDS.position.y, WANDER_BOUNDS.end.y)
	)

func respond(message: String) -> void:
	if _is_waiting:
		return
	_is_waiting = true
	emit_signal("response_ready", "...")

	var body := JSON.stringify({
		"model": Config.GROQ_MODEL,
		"messages": [
			{"role": "system", "content": SYSTEM_PROMPT},
			{"role": "user", "content": message}
		],
		"max_tokens": 120,
		"temperature": 0.8
	})

	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Config.GROQ_API_KEY
	]

	_http.request(Config.GROQ_URL, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_waiting = false
	if response_code != 200:
		emit_signal("response_ready", "[error " + str(response_code) + "]")
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		emit_signal("response_ready", "[parse error]")
		return
	var reply: String = json["choices"][0]["message"]["content"]
	emit_signal("response_ready", reply.strip_edges())
