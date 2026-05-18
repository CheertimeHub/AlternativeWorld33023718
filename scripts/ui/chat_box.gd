extends Control

@onready var message_log: RichTextLabel = $MessageLog
@onready var input_field: LineEdit = $InputField
@onready var send_button: Button = $SendButton

var linuxos: AnimatedSprite2D

func _ready() -> void:
	send_button.pressed.connect(_on_send)
	input_field.text_submitted.connect(_on_send)
	_append_message("[ LinuxOS is online ]", "#555555")

func setup(target: AnimatedSprite2D) -> void:
	linuxos = target
	linuxos.response_ready.connect(_on_linuxos_response)

func _on_send(_text: String = "") -> void:
	var msg := input_field.text.strip_edges()
	if msg.is_empty():
		return
	_append_message("> " + msg, "#88cc88")
	input_field.clear()
	if linuxos:
		linuxos.respond(msg)

func _on_linuxos_response(text: String) -> void:
	_append_message("LinuxOS: " + text, "#aaaaaa")

func _append_message(text: String, color: String) -> void:
	message_log.append_text("[color=" + color + "]" + text + "[/color]\n")
