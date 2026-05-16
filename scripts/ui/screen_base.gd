## Base class for all screens
extends Control
class_name ScreenBase

func on_enter() -> void:
	pass

func on_exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update_display() -> void:
	pass
