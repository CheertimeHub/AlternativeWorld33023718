extends Node2D

func _ready() -> void:
	var linuxos := $LinuxOS as AnimatedSprite2D
	var chat_box := $UI/ChatBox
	chat_box.setup(linuxos)
