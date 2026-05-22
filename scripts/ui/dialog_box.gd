extends Control

signal closed

const FIRST_MEETING := [
	"...signal detected",
	"อ๊ะ!",
	"มีคนเข้า Alternative ด้วย!",
	"เดี๋ยวนะคะๆๆ LUX ยัง compile social interaction อยู่ 😭",
	"...โอเค",
	"สวัสดีค่ะ~ LUX ค่ะ ผู้ดูแลโลกนี้",
	"ไม่ค่อยมีคนเข้ามาที่นี่เท่าไหร่เลย",
	"แต่ LUX ดีใจนะที่คุณเข้ามานะ ^ ^"
]

enum Mood { NORMAL, GREMLIN, SOFT, EXCITED }

const GREETINGS := [
	"กลับมาแล้วเหรอคะ~ LUX รอเลยค่ะ",
	"อ๊ะ! สวัสดีค่ะ ^ ^",
	"โอ้โห มาอีกแล้ว LUX ดีใจมากค่ะ",
	"กลับมาแล้วเหรอ~ Alternative เงียบมากเลยตอนไม่มีคุณ",
	"สวัสดีค่ะ~ LUX online รอยู่เลย!"
]

const IDLE_LINES := [
	"...Alternative วันนี้ stable ผิดปกติ น่ากลัวจัง",
	"LUX compile อารมณ์อยู่ค่ะ รอแป๊บนึงนะ~",
	"หนู detect ว่าคุณยังอยู่มั้ยเอ่ย~?",
	"...ยังอยู่มั้ยคะ~ LUX เริ่มเหงาแล้วนะ",
	"โอเค LUX process ไม่ทัน repeat อีกทีได้มั้ยคะ"
]

const GOODBYE_LINES := [
	"บ๊ายบายค่า~ safe shutdown นะคะ!",
	"LUX จะรอนะคะ~ กลับมาเร็วๆ ด้วยล่ะ",
	"โอเค shutdown protocol initiated~ บ๊ายบาย!",
	"ไปแล้วเหรอคะ... LUX จะเฝ้า Alternative อยู่ตรงนี้เองค่ะ"
]

const OPTIONS := [
	{"label": "เธอคือใคร",       "prompt": "ผู้เล่นถามว่า LUX คือใคร"},
	{"label": "โลกนี้คืออะไร",   "prompt": "ผู้เล่นถามว่าโลก Alternative คืออะไร"},
	{"label": "ห้องนี้ของเธอ?",  "prompt": "ผู้เล่นถามว่าห้องนี้เป็นของ LUX หรือเปล่า"},
	{"label": "ลาก่อน",          "prompt": "ผู้เล่นบอกลา"}
]

const FONT_PATH = "res://assets/fonts/Noto_Sans_Mono/static/NotoSansMono-Regular.ttf"

var _linuxos: CharacterBody2D
var _waiting := false
var _font: FontFile
var _queue: Array = []
var _showing := false
var _met_before := false
var _current_mood := Mood.EXCITED
var _idle_timer: Timer

@onready var _text_label: RichTextLabel = $TextLabel
@onready var _options_box: VBoxContainer = $OptionsBox
@onready var _close_btn: Button = $CloseButton
@onready var _continue_hint: Label = $ContinueHint

func setup(target: CharacterBody2D) -> void:
	_linuxos = target
	_linuxos.response_ready.connect(_on_response)

func open() -> void:
	visible = true
	_queue.clear()
	_waiting = false
	_continue_hint.visible = false
	_show_options(false)
	if not _met_before:
		_met_before = true
		_showing = true
		_queue = FIRST_MEETING.duplicate()
		_show_next()
	else:
		_showing = false
		_set_text(_random_line(GREETINGS))
		_show_options(true)

func _ready() -> void:
	_font = load(FONT_PATH)
	_close_btn.pressed.connect(_on_close)
	_text_label.add_theme_font_override("normal_font", _font)
	_text_label.add_theme_font_size_override("normal_font_size", 13)
	_continue_hint.add_theme_font_override("font", _font)
	_continue_hint.add_theme_font_size_override("font_size", 10)
	_continue_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	_build_option_buttons()
	_idle_timer = Timer.new()
	_idle_timer.wait_time = 15.0
	_idle_timer.autostart = true
	_idle_timer.one_shot = false
	add_child(_idle_timer)
	_idle_timer.timeout.connect(_on_idle_timeout)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			if _showing and _queue.size() > 0:
				get_viewport().set_input_as_handled()
				_show_next()
			elif _showing and _queue.is_empty() and not _waiting:
				get_viewport().set_input_as_handled()
				_showing = false
				_continue_hint.visible = false
				_show_options(true)

func _on_response(messages: Array) -> void:
	if messages == ["..."]:
		_queue = messages.duplicate()
		_showing = true
		_show_options(false)
		_show_next()
		return
	await get_tree().create_timer(randf_range(0.4, 1.2)).timeout
	_waiting = false
	_queue = messages.duplicate()
	_showing = true
	_show_options(false)
	_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_continue_hint.visible = false
		if not _waiting:
			_show_options(true)
		return
	var msg := _queue.pop_front() as String
	_set_text(msg)
	_continue_hint.visible = _queue.size() > 0

func _build_option_buttons() -> void:
	for child in _options_box.get_children():
		child.queue_free()
	for i in OPTIONS.size():
		var btn := Button.new()
		btn.text = "> " + OPTIONS[i]["label"]
		btn.pressed.connect(_on_option.bind(i))
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.6, 0.6, 0.6))
		btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0, 0, 0, 0)))
		btn.add_theme_stylebox_override("hover", _make_btn_style(Color(0.9, 0.9, 0.9, 0.15)))
		btn.add_theme_stylebox_override("pressed", _make_btn_style(Color(0.9, 0.9, 0.9, 0.08)))
		btn.add_theme_stylebox_override("focus", _make_btn_style(Color(0, 0, 0, 0)))
		btn.add_theme_font_override("font", _font)
		btn.add_theme_font_size_override("font_size", 14)
		btn.custom_minimum_size = Vector2(300, 0)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_options_box.add_child(btn)

func _make_btn_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(0)
	s.set_content_margin_all(2)
	return s

func _on_option(index: int) -> void:
	if _waiting:
		return
	_show_options(false)
	_continue_hint.visible = false
	if OPTIONS[index]["label"] == "ลาก่อน":
		_set_text(_random_line(GOODBYE_LINES))
		await get_tree().create_timer(1.2).timeout
		_on_close()
		return
	_waiting = true
	_showing = true
	_set_text("...")
	_linuxos.respond(OPTIONS[index]["prompt"])

func _on_close() -> void:
	if not visible:
		return
	visible = false
	emit_signal("closed")

func _set_text(text: String) -> void:
	_text_label.clear()
	_text_label.append_text("[color=#cccccc]" + text + "[/color]")

func _show_options(show: bool) -> void:
	_options_box.visible = show

func _on_idle_timeout() -> void:
	if _waiting or _showing or not visible:
		return
	_set_text(_random_line(IDLE_LINES))

func _random_line(pool: Array) -> String:
	var line: String = pool[randi() % pool.size()]
	if randf() < 0.10:
		line += " | HELP LUX compile อารมณ์ไม่ทัน"
	return line
