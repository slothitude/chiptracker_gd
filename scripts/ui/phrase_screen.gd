## Phrase screen: main pattern editor with grid, cursor, scrolling
extends "res://scripts/ui/screen_base.gd"

const CT = preload("res://scripts/constants.gd")

# Cursor state
var cursor_row: int = 0
var cursor_channel: int = 0
var cursor_column: int = 0  ## 0=note, 1=inst, 2=vol, 3=fx_type, 4=fx_val
var current_octave: int = 4
var current_instrument: int = 1
var scroll_offset: int = 0

# Display
var _labels: Array = []  ## [row * COLS_PER_ROW + col] = Label
var _header_labels: Array = []
var _cursor_blink: float = 0.0

const VISIBLE_ROWS := 28
const CHARS_PER_CHANNEL := 12  ## "C-4 01 .. 000 "
const COLS_PER_ROW := CT.NUM_CHANNELS * CHARS_PER_CHANNEL
const ROW_HEIGHT := 14
const FONT_SIZE := 11

# Colors
const COLOR_BG := Color("1a1a2e")
const COLOR_NOTE := Color("4ecca3")
const COLOR_INST := Color("6c5ce7")
const COLOR_VOL := Color("5555dd")
const COLOR_FX := Color("ffd93d")
const COLOR_CURSOR := Color("e94560")
const COLOR_PLAYHEAD := Color("4ecca3")
const COLOR_BEAT := Color("302848")
const COLOR_EMPTY := Color("444444")
const COLOR_TEXT := Color("cccccc")
const COLOR_HEADER := Color("222236")

func on_enter() -> void:
	_build_ui()
	InputManager.action_pressed.connect(_on_action)
	InputManager.note_pressed.connect(_on_note_pressed)
	update_display()

func on_exit() -> void:
	if InputManager.action_pressed.is_connected(_on_action):
		InputManager.action_pressed.disconnect(_on_action)
	if InputManager.note_pressed.is_connected(_on_note_pressed):
		InputManager.note_pressed.disconnect(_on_note_pressed)

func _build_ui() -> void:
	# Free existing labels
	for child in get_children():
		child.queue_free()
	_labels.clear()
	_header_labels.clear()

	# Channel headers
	var header_y := 0
	for ch in range(CT.NUM_CHANNELS):
		var lbl := Label.new()
		lbl.position = Vector2(ch * CHARS_PER_CHANNEL * 7 + 24, header_y)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_TEXT)
		lbl.text = CT.CHANNEL_NAMES[ch]
		add_child(lbl)
		_header_labels.append(lbl)

	# Row labels + data labels
	for row in range(VISIBLE_ROWS):
		var y := (row + 1) * ROW_HEIGHT + 4

		# Row number
		var row_lbl := Label.new()
		row_lbl.position = Vector2(2, y)
		row_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		row_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		row_lbl.text = "%02d" % row
		add_child(row_lbl)
		_header_labels.append(row_lbl)

		for ch in range(CT.NUM_CHANNELS):
			var x := ch * CHARS_PER_CHANNEL * 7 + 24
			var data_lbl := Label.new()
			data_lbl.position = Vector2(x, y)
			data_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
			data_lbl.add_theme_color_override("font_color", COLOR_NOTE)
			data_lbl.text = "--- .. .. --- "
			add_child(data_lbl)
			_labels.append(data_lbl)

func update_display() -> void:
	var song = SongManager.song
	var order_entry: PackedByteArray = song.order_list.get_entry(Sequencer.current_position)

	# Ensure scroll keeps cursor visible
	if cursor_row < scroll_offset:
		scroll_offset = cursor_row
	elif cursor_row >= scroll_offset + VISIBLE_ROWS:
		scroll_offset = cursor_row - VISIBLE_ROWS + 1

	# Update header row numbers
	for row in range(VISIBLE_ROWS):
		var actual_row := row + scroll_offset
		if row + 2 < _header_labels.size():
			_header_labels[row + 2].text = "%02d" % actual_row

	# Update pattern data
	for row in range(VISIBLE_ROWS):
		var actual_row := row + scroll_offset
		for ch in range(CT.NUM_CHANNELS):
			var idx := row * CT.NUM_CHANNELS + ch
			if idx >= _labels.size():
				continue
			var lbl: Label = _labels[idx]
			var pat_idx: int = order_entry[ch]
			var pat = song.get_pattern(pat_idx)
			var cell = pat.get_cell(actual_row, ch)

			var text := "%s %s %s %s" % [
				cell.format_note(),
				cell.format_instrument(),
				cell.format_volume(),
				cell.format_effect()
			]
			lbl.text = text

			# Color coding
			if actual_row == cursor_row and ch == cursor_channel:
				lbl.add_theme_color_override("font_color", COLOR_CURSOR)
			elif Sequencer.state == Sequencer.State.PLAYING and actual_row == Sequencer.current_row:
				lbl.add_theme_color_override("font_color", COLOR_PLAYHEAD)
			elif actual_row % 4 == 0:
				lbl.add_theme_color_override("font_color", COLOR_NOTE)
			else:
				lbl.add_theme_color_override("font_color", COLOR_TEXT)

func _on_action(action: String) -> void:
	match action:
		"ui_up":
			cursor_row = maxi(0, cursor_row - 1)
		"ui_down":
			cursor_row = mini(CT.PATTERN_ROWS - 1, cursor_row + 1)
		"ui_left":
			cursor_column = (cursor_column - 1) % 5
			if cursor_column < 0:
				cursor_column = 4
				cursor_channel = (cursor_channel - 1) % CT.NUM_CHANNELS
				if cursor_channel < 0:
					cursor_channel = CT.NUM_CHANNELS - 1
		"ui_right":
			cursor_column = (cursor_column + 1) % 5
			if cursor_column == 0:
				cursor_channel = (cursor_channel + 1) % CT.NUM_CHANNELS
		"action_l1":
			cursor_channel = (cursor_channel - 1) % CT.NUM_CHANNELS
			if cursor_channel < 0:
				cursor_channel = CT.NUM_CHANNELS - 1
		"action_r1":
			cursor_channel = (cursor_channel + 1) % CT.NUM_CHANNELS
		"action_l2":
			current_octave = maxi(0, current_octave - 1)
		"action_r2":
			current_octave = mini(7, current_octave + 1)
		"action_a":
			_insert_note_at_cursor()
		"action_b":
			_clear_cell_at_cursor()
		"action_start":
			Sequencer.toggle_playback()
		"select_right":
			ScreenManager.push_screen(load("res://scripts/ui/song_screen.gd").new())
		"select_left":
			ScreenManager.push_screen(load("res://scripts/ui/instrument_screen.gd").new())
		"select_down":
			ScreenManager.push_screen(load("res://scripts/ui/file_screen.gd").new())
	update_display()

func _on_note_pressed(semitone: int) -> void:
	var note := current_octave * 12 + semitone + 1
	if note >= CT.NOTE_MIN and note <= CT.NOTE_MAX:
		_set_cell_note(note)

func _insert_note_at_cursor() -> void:
	# Insert a note at current octave's C
	var note := current_octave * 12 + 1
	if note >= CT.NOTE_MIN and note <= CT.NOTE_MAX:
		_set_cell_note(note)

func _set_cell_note(note: int) -> void:
	var song = SongManager.song
	var order_entry: PackedByteArray = song.order_list.get_entry(Sequencer.current_position)
	var pat_idx: int = order_entry[cursor_channel]
	var pat = song.get_pattern(pat_idx)
	var cell = pat.get_cell(cursor_row, cursor_channel)
	cell.note = note
	cell.instrument = current_instrument
	# Advance cursor down
	cursor_row = mini(CT.PATTERN_ROWS - 1, cursor_row + 1)
	update_display()

func _clear_cell_at_cursor() -> void:
	var song = SongManager.song
	var order_entry: PackedByteArray = song.order_list.get_entry(Sequencer.current_position)
	var pat_idx: int = order_entry[cursor_channel]
	var pat = song.get_pattern(pat_idx)
	pat.get_cell(cursor_row, cursor_channel).clear()
	update_display()

func _process(delta: float) -> void:
	_cursor_blink += delta
	if _cursor_blink >= 0.4:
		_cursor_blink = 0.0
	if Sequencer.state == Sequencer.State.PLAYING:
		update_display()
