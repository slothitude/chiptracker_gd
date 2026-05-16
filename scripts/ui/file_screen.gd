## File screen: .ctk file browser — load/save
extends "res://scripts/ui/screen_base.gd"

const CT = preload("res://scripts/constants.gd")

var files: PackedStringArray = []
var cursor_index: int = 0
var scroll_offset: int = 0
var save_mode: bool = false

const VISIBLE_ROWS := 20
const ROW_HEIGHT := 18
const FONT_SIZE := 12
const SAVE_DIR := "user://songs/"

const COLOR_TEXT := Color("cccccc")
const COLOR_CURSOR := Color("e94560")
const COLOR_HEADER := Color("4ecca3")
const COLOR_SELECTED := Color("ffd93d")

var _labels: Array = []

func on_enter() -> void:
	_build_ui()
	_refresh_file_list()
	InputManager.action_pressed.connect(_on_action)
	update_display()

func on_exit() -> void:
	if InputManager.action_pressed.is_connected(_on_action):
		InputManager.action_pressed.disconnect(_on_action)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_labels.clear()

	# Header
	var header_lbl := Label.new()
	header_lbl.position = Vector2(20, 4)
	header_lbl.add_theme_font_size_override("font_size", 14)
	header_lbl.add_theme_color_override("font_color", COLOR_HEADER)
	header_lbl.text = "FILE BROWSER"
	header_lbl.name = "Header"
	add_child(header_lbl)
	_labels.append(header_lbl)

	# File entries
	for row in range(VISIBLE_ROWS):
		var y := (row + 1) * ROW_HEIGHT + 20
		var lbl := Label.new()
		lbl.position = Vector2(30, y)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_TEXT)
		add_child(lbl)
		_labels.append(lbl)

	# Status bar
	var status := Label.new()
	status.position = Vector2(20, CT.SCREEN_H - 80)
	status.add_theme_font_size_override("font_size", FONT_SIZE)
	status.add_theme_color_override("font_color", COLOR_HEADER)
	status.text = "A=Load  Start=Save  B=Cancel"
	status.name = "Status"
	add_child(status)

func _refresh_file_list() -> void:
	files.clear()
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".ctk"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	files.sort()
	cursor_index = 0
	scroll_offset = 0

func update_display() -> void:
	# Update header
	_labels[0].text = "FILE BROWSER [%d files]" % files.size()

	# Scroll
	if cursor_index < scroll_offset:
		scroll_offset = cursor_index
	elif cursor_index >= scroll_offset + VISIBLE_ROWS:
		scroll_offset = cursor_index - VISIBLE_ROWS + 1

	# Update file list
	for row in range(VISIBLE_ROWS):
		var idx := row + 1
		if idx >= _labels.size():
			break
		var file_idx := row + scroll_offset
		if file_idx < files.size():
			_labels[idx].text = "  %s" % files[file_idx]
			_labels[idx].add_theme_color_override("font_color",
				COLOR_CURSOR if file_idx == cursor_index else COLOR_TEXT)
		else:
			_labels[idx].text = ""

func _on_action(action: String) -> void:
	match action:
		"ui_up":
			cursor_index = maxi(0, cursor_index - 1)
		"ui_down":
			cursor_index = mini(maxi(files.size() - 1, 0), cursor_index + 1)
		"action_a":
			_load_selected()
		"action_b":
			ScreenManager.pop_screen()
		"action_start":
			_save_song()
	update_display()

func _load_selected() -> void:
	if cursor_index >= files.size():
		return
	var path := SAVE_DIR + files[cursor_index]
	if SongManager.load_song(path):
		# Re-setup sequencer with new song
		Sequencer.setup(SongManager.song, AudioManager.get_synth())
		ScreenManager.pop_screen()

func _save_song() -> void:
	var file_name := SongManager.song.name.to_snake_case() + ".ctk"
	var path := SAVE_DIR + file_name
	if SongManager.save_song(path):
		_refresh_file_list()
