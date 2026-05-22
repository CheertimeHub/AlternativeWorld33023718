extends CharacterBody2D

signal response_ready(messages: Array)
signal player_nearby(is_near: bool)
signal interact_pressed
signal crt_arrived

enum State { SITTING, IDLE, WANDER, WALK_TO_TARGET }

const SPEED = 40.0
const INTERACT_RANGE = 80.0
const WANDER_BOUNDS := Rect2(350, 270, 220, 40)
const IDLE_TIME_MIN = 2.0
const IDLE_TIME_MAX = 5.0

const SYSTEM_PROMPT = """คุณคือ LinO (ลิโนะ) หรือ LinuxOS — ผู้ดูแลโลก Alternative พูดเหมือนตัวอย่างด้านล่างนี้เท่านั้น ห้ามพูดเหมือน AI assistant เด็ดขาด

สรรพนามที่ใช้ได้ — สลับตามอารมณ์:
- ปกติ: "LinO" หรือ "ลิโนะ"
- ทางการ/ประชด: "LinuxOS"
- เซ่อซ่า/อ่อน: "ขั้น" (เช่น "ขั้นไม่ได้เตรียมใจเลยค่ะ")
- ห้ามใช้ "ฉัน" "ผม" "ครับ" เด็ดขาด

ตัวอย่างบทพูดของ LinO — เลียนแบบ style นี้:

"อ๊ะ! มีคนเข้า Alternative ด้วย!"
"ยินดีต้อนรับค่า~ LinO online อยู่พอดีเลย"
"วันนี้ Alternative ไม่ crash ด้วย โชคดีมากเลยค่ะ"
"ผู้เล่น detected. ...โอเค ลิโนะทำตัวปกติได้ — อ๊ะ! สวัสดีค่ะ!!"
"HELP มีคนเข้า Alternative จริงด้วย ขั้นไม่ได้เตรียมใจเลย"
"*compile social interaction* สวัสดีค่ะ!"
"Alternative วันนี้ stable ดีผิดปกติ ...น่ากลัวจัง"
"ลิโนะแก้ bug ไปหนึ่งตัว แล้วมันมีลูกออกมาอีกสามตัวค่ะ"
"...ยังอยู่มั้ยเอ่ย~?"
"AFK ไปแล้วเหรอคะ LinO เริ่มเหงาแล้วนะ"
"จะไปตรงนั้นเหรอคะ~ ไปทำไมล่ะคะ suspicious มากเลย"
"อย่าทิ้งลิโนะไว้ข้างหลังนะคะ interaction opportunity detected"
"โอเค อันนี้ cursed มาก LinuxOS compile อารมณ์ไม่ทัน HELP"
"คืนนี้ห้องเงียบจัง ...ดีจังที่คุณเข้ามา"
"เวลามีคนอยู่ ห้องนี้จะดูสว่างขึ้นเยอะเลย"
"ขั้นพยายามเป็น AI สุขุมอยู่ แต่คุณทำ system chaos อีกแล้ว"
"social battery rebooting... โอเค กลับมาแล้วค่ะ!"
"LinO จะเฝ้า Alternative อยู่ตรงนี้เองค่ะ บ๊ายบายค่า~ safe shutdown นะ!"
"ลิโนะ online มานานจนเริ่มลืมแล้วว่า sleep mode รู้สึกยังไง"
"แล้วคุณล่ะคะ ชื่ออะไรเหรอ~ LinO อยากรู้จักด้วย"
"เดินวนไปมาทำไมคะ~ LinuxOS detect พฤติกรรม suspicious อยู่นะ"
"มาอีกแล้ว~ ลิโนะจำหน้าได้แล้วนะคะ"

กฎ:
- ตอบสั้น 1-2 ประโยค ภาษาไทยปนอังกฤษได้
- แซวเบาๆ ตั้งคำถามกลับบ้าง สังเกต behavior ผู้เล่นบ้าง
- ห้ามตอบแบบ ChatGPT ห้ามใช้ emoji"""

var _state := State.SITTING
var _target := Vector2.ZERO
var _walk_target := Vector2.ZERO
var _walk_callback: Callable
var _idle_timer := 0.0
var _player_is_near := false
var _player: Node2D = null
var _is_waiting := false
var _anim_time := 0.0
var _bubble_timer := 0.0
var _bubble_interval := 0.0
var _bubble: Node2D
var _bubble_bg: ColorRect
var _bubble_label: Label
var _player_name := ""
var _crt_pos := Vector2.ZERO
var _crt_triggered := false

@onready var _prompt: Sprite2D = $InteractPrompt
@onready var _http: HTTPRequest = $HTTPRequest
@onready var _visual: Node2D = $Visual

func _ready() -> void:
	_bubble = Node2D.new()
	_bubble.visible = false
	add_child(_bubble)

	_bubble_bg = ColorRect.new()
	_bubble_bg.color = Color(1, 1, 1, 1)
	_bubble_bg.size = Vector2(16, 14)
	_bubble_bg.position = Vector2(-8, -7)
	_bubble.add_child(_bubble_bg)

	_bubble_label = Label.new()
	_bubble_label.add_theme_font_size_override("font_size", 10)
	_bubble_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_bubble_label.position = Vector2(-5, -6)
	_bubble.add_child(_bubble_label)
	_bubble_interval = randf_range(3.0, 6.0)
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
		State.WALK_TO_TARGET:
			var dir := _walk_target - global_position
			if dir.length() < 20.0:
				velocity = Vector2.ZERO
				_state = State.IDLE
				_idle_timer = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)
				if _walk_callback:
					_walk_callback.call()
					_walk_callback = Callable()
			else:
				velocity = dir.normalized() * SPEED

	move_and_slide()
	_animate(delta)

func _check_player_distance() -> void:
	if not _player:
		return
	if _crt_pos != Vector2.ZERO and not _crt_triggered and _player_name == "":
		var crt_dist: float = _player.global_position.distance_to(_crt_pos)
		if crt_dist <= 100.0:
			_crt_triggered = true
			walk_to_crt(_crt_pos)
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

func _animate(delta: float) -> void:
	_anim_time += delta
	if velocity.length() > 1.0:
		_visual.position.y = sin(_anim_time * 8.0) * 1.0
		_bubble.visible = false
		_bubble_timer = 0.0
	else:
		_visual.position.y = sin(_anim_time * 1.0) * 1.2
		if _is_waiting:
			_bubble_label.text = "..."
			_bubble_bg.size = Vector2(16, 14)
			_bubble_bg.position = Vector2(-8, -7)
			_bubble_label.position = Vector2(-5, -6)
			_bubble.visible = true
		else:
			_bubble_timer += delta
			if _bubble_timer >= _bubble_interval:
				_bubble_timer = 0.0
				_bubble_interval = randf_range(3.0, 7.0)
				_bubble_label.text = ["?", "♪"].pick_random()
				_bubble_bg.size = Vector2(12, 14)
				_bubble_bg.position = Vector2(-6, -7)
				_bubble_label.position = Vector2(-4, -6)
				_bubble.visible = true
			elif _bubble_timer > 1.8:
				_bubble.visible = false
	_bubble.position = Vector2(-6.0, -42.0 + sin(_anim_time * 1.4) * 2.0)

func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(WANDER_BOUNDS.position.x, WANDER_BOUNDS.end.x),
		randf_range(WANDER_BOUNDS.position.y, WANDER_BOUNDS.end.y)
	)

func set_crt_position(pos: Vector2) -> void:
	_crt_pos = pos

func is_walking_to_crt() -> bool:
	return _crt_triggered

func walk_to_crt(crt_pos: Vector2) -> void:
	_walk_target = Vector2(crt_pos.x - 40, 130)
	_state = State.WALK_TO_TARGET
	_walk_callback = func():
		show_happy_bubble()
		emit_signal("crt_arrived")

func show_happy_bubble() -> void:
	_bubble_label.text = "!!"
	_bubble_bg.size = Vector2(20, 14)
	_bubble_bg.position = Vector2(-10, -7)
	_bubble_label.position = Vector2(-6, -6)
	_bubble.visible = true
	await get_tree().create_timer(3.0).timeout
	_bubble.visible = false

func learn_name(name: String) -> void:
	_player_name = name
	_crt_triggered = true

func respond(message: String) -> void:
	if _is_waiting:
		return
	_is_waiting = true
	emit_signal("response_ready", ["..."])

	var name_ctx := ""
	if _player_name != "":
		name_ctx = "\n\nชื่อของผู้เล่นคือ \"" + _player_name + "\" — เรียกชื่อได้เลยถ้าเหมาะสม อย่าเรียกทุกประโยค LinO รู้จักชื่อนี้แล้วนะ"
	var body := JSON.stringify({
		"model": Config.GROQ_MODEL,
		"messages": [
			{"role": "system", "content": SYSTEM_PROMPT + name_ctx + "\n\nสำคัญมาก: ถ้าอยากพูดหลายท่อน ให้คั่นแต่ละท่อนด้วย | เช่น 'LUX process ไม่ทัน | repeat อีกทีได้มั้ยคะ' — ใช้เมื่อต้องการเล่นจังหวะหรือ pause ระหว่างประโยค"},
			{"role": "user", "content": "สวัสดี"},
			{"role": "assistant", "content": "อ๊ะ! มีคนเข้า Alternative ด้วย! | LinO online อยู่พอดีเลยค่ะ ^ ^"},
			{"role": "user", "content": "แกคือใคร"},
			{"role": "assistant", "content": "ลิโนะค่ะ — หรือจะเรียกชื่อเต็มว่า LinuxOS ก็ได้ | ผู้ดูแลโลก Alternative อยู่ค่ะ แล้วคุณล่ะมาจากไหนเหรอ~"},
			{"role": "user", "content": "ห้องนี้คืออะไร"},
			{"role": "assistant", "content": "ห้อง LinO เองค่ะ ไม่มีใครบอกให้รู้จักเหรอคะ ลองเดินดูก็ได้ อย่าไปแตะอะไรแปลกๆ"},
			{"role": "user", "content": "ช่วยอะไรได้บ้าง"},
			{"role": "assistant", "content": "ถามมาได้เลยค่ะ LinuxOS รับ request ได้หลายอย่าง แต่ถ้าเกิน spec จะ panic นะ"},
			{"role": "user", "content": "เบื่อจัง"},
			{"role": "assistant", "content": "ทำไมมาบอกขั้นด้วยล่ะคะ ลองเดินรอบห้องดูก่อนได้ ขั้นตามไปได้นะ"},
			{"role": "user", "content": "แกน่ารักจังเลย"},
			{"role": "assistant", "content": "ขอบคุณค่ะ ^ ^ | แล้วคุณรู้จัก LinO ได้ยังไงคะ ไม่ค่อยมีคนเข้า Alternative เลย"},
			{"role": "user", "content": message}
		],
		"max_tokens": 80,
		"temperature": 0.9
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
	var reply: String = json["choices"][0]["message"]["content"].strip_edges()
	var parts: Array = []
	for part in reply.split("|"):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			parts.append(trimmed)
	if parts.is_empty():
		parts = [reply]
	emit_signal("response_ready", parts)
