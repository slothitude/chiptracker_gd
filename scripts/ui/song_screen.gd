## Song screen: order list editor
extends "res://scripts/ui/screen_base.gd"

const CT = preload("res://scripts/constants.gd")

var cursor_pos: int = 0
var cursor_channel: int = 0
var scroll_offset: int = 0

const VISIBLE_ROWS := 20
const ROW_HEIGHT := 18
const FONT_SIZE := 12

const COLOR_TEXT := Color("cccccc")
const COLOR_HEADER := Color("4ecca3")
const COLOR_CURSOR := Color("e94560")
const COLOR_POS := Color("ffd93d")

var _labels: Array = []

func on_enter() -> void:
	_build_ui()
	InputManager.action_pressed.connect(_on_action)
	update_display()

func on_exit() -> void:
	if InputManager.action_pressed.is_connected(_on_action):
		InputManager.action_pressed.disconnect(_on_action)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_labels.clear()

	# Column headers
	var headers := ["POS", "PU1", "PU2", "TRI", "NSE"]
	for i in range(headers.size()):
		var lbl := Label.new()
		lbl.position = Vector2(i * 80 + 20, 0)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_HEADER)
		lbl.text = headers[i]
		add_child(lbl)

	# Data rows
	for row in range(VISIBLE_ROWS):
		var y := (row + 1) * ROW_HEIGHT + 4

		# Position number
		var pos_lbl := Label.new()
		pos_lbl.position = Vector2(20, y)
		pos_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		pos_lbl.add_theme_color_override("font_color", COLOR_POS)
		add_child(pos_lbl)
		_labels.append(pos_lbl)

		# Channel pattern indices
		for ch in range(CT.NUM_CHANNELS):
			var lbl := Label.new()
			lbl.position = Vector2((ch + 1) * 80 + 20, y)
			lbl.add_theme_font_size_override("font_size", FONT_SIZE)
			lbl.add_theme_color_override("font_color", COLOR_TEXT)
			add_child(lbl)
			_labels.append(lbl)

func update_display() -> void:
	var song := SongManager.song
	var ol := song.order_list

	# Scroll
	if cursor_pos < scroll_offset:
		scroll_offset = cursor_pos
	elif cursor_pos >= scroll_offset + VISIBLE_ROWS:
		scroll_offset = cursor_pos - VISIBLE_ROWS + 1

	for row in range(VISIBLE_ROWS):
		var actual_pos := row + scroll_offset
		var base := row * (CT.NUM_CHANNELS + 1)

		# Position label
		if base < _labels.size():
			_labels[base].text = "%02d" % actual_pos if actual_pos < ol.length else ""
			_labels[base].add_theme_color_override("font_color",
				COLOR_CURSOR if actual_pos == cursor_pos else COLOR_POS)

		# Channel indices
		for ch in range(CT.NUM_CHANNELS):
			var idx := base + 1 + ch
			if idx >= _labels.size():
				continue
			if actual_pos < ol.length:
				_labels[idx].text = "%02d" % ol.get_pattern_index(actual_pos, ch)
				_labels[idx].add_theme_color_override("font_color",
					COLOR_CURSOR if actual_pos == cursor_pos and ch == cursor_channel else COLOR_TEXT)
			else:
				_labels[idx].text = ""

func _on_action(action: String) -> void:
	var song := SongManager.song
	var ol := song.order_list

	match action:
		"ui_up":
			cursor_pos = maxi(0, cursor_pos - 1)
		"ui_down":
			cursor_pos = mini(ol.length - 1, cursor_pos + 1)
		"ui_left":
			cursor_channel = (cursor_channel - 1) % CT.NUM_CHANNELS
			if cursor_channel < 0:
				cursor_channel = CT.NUM_CHANNELS - 1
		"ui_right":
			cursor_channel = (cursor_channel + 1) % CT.NUM_CHANNELS
		"action_a":
			if cursor_pos < ol.length:
				var val := ol.get_pattern_index(cursor_pos, cursor_channel)
				ol.set_pattern_index(cursor_pos, cursor_channel, (val + 1) % CT.MAX_PATTERNS)
		"action_b":
			if cursor_pos < ol.length:
				var val := ol.get_pattern_index(cursor_pos, cursor_channel)
				ol.set_pattern_index(cursor_pos, cursor_channel, (val - 1 + CT.MAX_PATTERNS) % CT.MAX_PATTERNS)
		"select_up", "select_down":
			ScreenManager.pop_screen()
	update_display()
