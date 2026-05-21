extends Node2D

func _ready() -> void:
	var linuxos := $LinuxOS
	var dialog := $UI/DialogBox
	dialog.setup(linuxos)
	linuxos.interact_pressed.connect(func():
		if not dialog.visible:
			dialog.open()
	)
