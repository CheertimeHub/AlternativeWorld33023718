extends Control

signal closed
signal name_entered(player_name: String)

const FIRST_MEETING := [
	"...signal detected",
	"อ๊ะ!",
	"มีคนเข้า Alternative ด้วยล่ะ!",
	"เดี๋ยวนะคะๆๆ LinO ยัง compile social interaction อยู่ 😭",
	"ฮึ้บ ~ ...โอเค !",
	"สวัสดีค่ะ ~ LinuxOS system online เองค่ะ",
	"...",
	"แต่เรียก LINO ก็ได้นะคะ ^ ^"
]

enum Mood { NORMAL, GREMLIN, SOFT, EXCITED }

const GREETINGS := [
	"กลับมาแล้วเหรอคะ~ LinO รอเลยค่ะ",
	"อ๊ะ! สวัสดีค่ะ ^ ^",
	"โอ้โห มาอีกแล้ว LinO ดีใจมากค่ะ",
	"กลับมาแล้วเหรอ~ Alternative เงียบมากเลยตอนไม่มีคุณ",
	"สวัสดีค่ะ~ LinO online รอยู่เลย!"
]

const IDLE_LINES := [
	"...Alternative วันนี้ stable ผิดปกติ น่ากลัวจัง",
	"LinO compile อารมณ์อยู่ค่ะ รอแป๊บนึงนะ~",
	"ขั้น detect ว่าคุณยังอยู่มั้ยเอ่ย~?",
	"...ยังอยู่มั้ยคะ~ LinO เริ่มเหงาแล้วนะ",
	"โอเค LinO process ไม่ทัน repeat อีกทีได้มั้ยคะ"
]

const GOODBYE_LINES := [
	"บ๊ายบายค่า~ safe shutdown นะคะ!",
	"LinO จะรอนะคะ~ กลับมาเร็วๆ ด้วยล่ะ",
	"โอเค shutdown protocol initiated~ บ๊ายบาย!",
	"ไปแล้วเหรอคะ... LinO จะเฝ้า Alternative อยู่ตรงนี้เองค่ะ"
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
var met_before: bool:
	get: return _met_before
var _current_mood := Mood.EXCITED
var _idle_timer: Timer
var _name_input: LineEdit
var _name_mode := false

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
	_name_input = LineEdit.new()
	_name_input.visible = false
	_name_input.placeholder_text = "พิมพ์ชื่อของคุณ..."
	_name_input.add_theme_font_override("font", _font)
	_name_input.add_theme_font_size_override("font_size", 14)
	_name_input.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_name_input.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.4))
	_name_input.offset_left = 330.0
	_name_input.offset_top = 450.0
	_name_input.offset_right = 630.0
	_name_input.offset_bottom = 478.0
	_name_input.text_submitted.connect(_on_name_submitted)
	add_child(_name_input)
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
				if _name_mode:
					_name_mode = false
					_on_close()
				else:
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
		if _name_mode and not _waiting:
			_name_input.visible = true
			_name_input.text = ""
			_name_input.grab_focus()
		elif not _waiting:
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

func open_name_input() -> void:
	visible = true
	_name_mode = true
	_show_options(false)
	_continue_hint.visible = false
	_queue = [
		"อ๊ะ?",
		"คุณมาดู CRT ของ LinO เหรอคะ~",
		"...",
		"อ๋อ จริงสิ!",
		"ตรงนี้พิมพ์ชื่อได้นะคะ",
		"LinO จะได้เรียกคุณถูก ^ ^",
		"ไม่งั้น LinO ต้องเรียกว่า \"เฮ้คุณตรงนั้น\" ตลอดเลย",
		"...ซึ่งมันแปลกมากอ่า~ 😭"
	]
	_showing = true
	_show_next()

func _on_name_submitted(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	_name_input.visible = false
	_showing = true
	_queue = [
		"\"" + trimmed + "\" เหรอคะ~",
		"โอเค!",
		"LinO จำได้แล้วค่ะ ~ ^ ^",
		"...",
		" ฮี่ฮี่ ~ ตอนนี้มีคนให้ลิโนะเรียกชื่อแล้ว",
		"ถ้าอยากคุยอีกก็กด E มาหาได้ตลอดนะคะ~"
	]
	_show_options(false)
	_show_next()
	emit_signal("name_entered", trimmed)

func _on_idle_timeout() -> void:
	if _waiting or _showing or not visible:
		return
	_set_text(_random_line(IDLE_LINES))

func _random_line(pool: Array) -> String:
	var line: String = pool[randi() % pool.size()]
	if randf() < 0.10:
		line += " | HELP LUX compile อารมณ์ไม่ทัน"
	return line
