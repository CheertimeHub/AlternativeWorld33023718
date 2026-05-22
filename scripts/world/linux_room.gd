extends Node2D

var _player_name := ""

@onready var _linuxos := $LinuxOS
@onready var _dialog := $UI/DialogBox
@onready var _crt_core := $Furniture/CRT_Core

func _ready() -> void:
	_dialog.setup(_linuxos)

	_linuxos.interact_pressed.connect(func():
		if not _dialog.visible and (_player_name != "" or not _linuxos.is_walking_to_crt()):
			_dialog.open()
	)

	_linuxos.crt_arrived.connect(func():
		_dialog.open_name_input()
	)

	_dialog.name_entered.connect(func(player_name: String):
		_player_name = player_name
		_linuxos.learn_name(player_name)
	)

	_dialog.closed.connect(func():
		if _dialog.met_before and _player_name == "":
			_linuxos.set_crt_position(_crt_core.global_position)
	)
