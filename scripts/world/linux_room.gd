extends Node2D

func _ready() -> void:
	var linuxos := $LinuxOS
	var chat_box := $UI/ChatBox
	chat_box.setup(linuxos)
	chat_box.visible = false
	linuxos.player_nearby.connect(func(is_near: bool):
		chat_box.visible = is_near
	)
