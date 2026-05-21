extends Control

signal closed

const OPTIONS := [
	{"label": "สวัสดี",          "prompt": "ผู้เล่นทักทายเธอ พูดทักทายกลับสั้นๆ ด้วยนิสัยเป็นกันเองและขำขันเล็กน้อย"},
	{"label": "ห้องนี้คืออะไร", "prompt": "ผู้เล่นถามว่าห้องนี้คืออะไร อธิบายว่านี่คือห้องของเธอ มี CRT เยอะเพราะชอบ"},
	{"label": "ช่วยอะไรได้บ้าง","prompt": "ผู้เล่นถามว่าเธอช่วยอะไรได้บ้าง ตอบอย่างเป็นกันเองว่าช่วยได้แค่ไหน"},
	{"label": "ลาก่อน",          "prompt": "ผู้เล่นบอกลา ตอบลาสั้นๆ ขำๆ"}
]

const FONT_PATH = "res://assets/fonts/Noto_Sans_Mono/static/NotoSansMono-Regular.ttf"

var _linuxos: CharacterBody2D
var _waiting := false
var _font: FontFile

@onready var _text_label: RichTextLabel = $TextLabel
@onready var _options_box: VBoxContainer = $OptionsBox
@onready var _close_btn: Button = $CloseButton

func setup(target: CharacterBody2D) -> void:
	_linuxos = target
	_linuxos.response_ready.connect(_on_response)

func open() -> void:
	visible = true
	_set_text("...")
	_show_options(true)

func _ready() -> void:
	_font = load(FONT_PATH)
	_close_btn.pressed.connect(_on_close)
	_text_label.add_theme_font_override("normal_font", _font)
	_text_label.add_theme_font_size_override("normal_font_size", 13)
	_build_option_buttons()
	visible = false

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
	_waiting = true
	_show_options(false)
	_set_text("...")
	_linuxos.respond(OPTIONS[index]["prompt"])

func _on_response(text: String) -> void:
	_waiting = false
	_set_text(text)
	_show_options(true)

func _on_close() -> void:
	visible = false
	emit_signal("closed")

func _set_text(text: String) -> void:
	_text_label.clear()
	_text_label.append_text("[color=#cccccc]" + text + "[/color]")

func _show_options(show: bool) -> void:
	_options_box.visible = show
