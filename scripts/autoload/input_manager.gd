## Input manager autoload: InputMap polling, key repeat, keyboard piano
extends Node

signal action_pressed(action: String)
signal action_released(action: String)
signal note_pressed(note: int)

const REPEAT_DELAY: float = 0.3
const REPEAT_RATE: float = 0.08

var _held_actions: Dictionary = {}
var _composite_select: bool = false

const PIANO_MAP: Dictionary = {
	KEY_A: 0, KEY_W: 1, KEY_S: 2, KEY_E: 3,
	KEY_D: 4, KEY_F: 5, KEY_T: 6, KEY_G: 7,
	KEY_Y: 8, KEY_H: 9, KEY_U: 10, KEY_J: 11, KEY_K: 12,
}

var _piano_keys_pressed: Dictionary = {}

func _process(delta: float) -> void:
	for action in _held_actions.keys():
		_held_actions[action] = float(_held_actions[action]) + delta
		if float(_held_actions[action]) >= REPEAT_DELAY:
			var elapsed: float = float(_held_actions[action]) - REPEAT_DELAY
			var count: int = int(elapsed / REPEAT_RATE)
			var prev_count: int = int((elapsed - delta) / REPEAT_RATE)
			if count > prev_count:
				action_pressed.emit(action)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_select"):
		_composite_select = true
	elif event.is_action_released("action_select"):
		_composite_select = false

	for dir in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action_pressed(dir):
			if _composite_select:
				action_pressed.emit("select_" + dir.trim_prefix("ui_"))
			else:
				action_pressed.emit(dir)
				_held_actions[dir] = 0.0
		elif event.is_action_released(dir):
			_held_actions.erase(dir)

	for action in ["action_a", "action_b", "action_x", "action_y",
					"action_l1", "action_r1", "action_l2", "action_r2", "action_start"]:
		if event.is_action_pressed(action):
			action_pressed.emit(action)
		elif event.is_action_released(action):
			action_released.emit(action)

	if event is InputEventKey and not event.echo:
		var key_event: InputEventKey = event
		var keycode: int = key_event.physical_keycode
		if PIANO_MAP.has(keycode):
			if key_event.pressed:
				if not _piano_keys_pressed.has(keycode):
					_piano_keys_pressed[keycode] = true
					note_pressed.emit(int(PIANO_MAP[keycode]))
			else:
				_piano_keys_pressed.erase(keycode)

func is_select_held() -> bool:
	return _composite_select
