## Screen manager autoload: push/pop screen stack
extends Node

const ScreenBase = preload("res://scripts/ui/screen_base.gd")

var _stack: Array = []  ## Array of ScreenBase
var _container: Control

func setup(container: Control) -> void:
	_container = container

func push_screen(screen: ScreenBase) -> void:
	if _stack.size() > 0:
		_stack[-1].on_exit()
		_stack[-1].visible = false
	_stack.append(screen)
	if _container:
		_container.add_child(screen)
	screen.on_enter()
	screen.visible = true

func pop_screen() -> void:
	if _stack.size() <= 1:
		return
	var old: ScreenBase = _stack.pop_back()
	old.on_exit()
	old.visible = false
	if _container:
		_container.remove_child(old)
		old.queue_free()
	if _stack.size() > 0:
		_stack[-1].visible = true
		_stack[-1].on_enter()

func replace_screen(screen: ScreenBase) -> void:
	if _stack.size() > 0:
		var old: ScreenBase = _stack.pop_back()
		old.on_exit()
		if _container:
			_container.remove_child(old)
			old.queue_free()
	_stack.append(screen)
	if _container:
		_container.add_child(screen)
	screen.on_enter()
	screen.visible = true

func current_screen() -> ScreenBase:
	if _stack.size() == 0:
		return null
	return _stack[-1]
