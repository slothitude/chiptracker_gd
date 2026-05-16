## Instrument screen: parameter editor with value bars
extends "res://scripts/ui/screen_base.gd"

const CT = preload("res://scripts/constants.gd")

var current_instrument: int = 0
var cursor_field: int = 0

const FIELD_COUNT := 9
const FONT_SIZE := 12
const ROW_HEIGHT := 22
const BAR_WIDTH := 200

const COLOR_TEXT := Color("cccccc")
const COLOR_LABEL := Color("4ecca3")
const COLOR_VALUE := Color("ffd93d")
const COLOR_BAR_BG := Color("333344")
const COLOR_BAR_FG := Color("6c5ce7")
const COLOR_CURSOR := Color("e94560")

const FIELD_NAMES: PackedStringArray = [
	"Waveform", "Attack", "Decay", "Sustain", "Release",
	"Vibrato Speed", "Vibrato Depth", "Pulse Width", "Volume"
]

var _labels: Array = []
var _bars: Array = []

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
	_bars.clear()

	# Instrument name header
	var name_lbl := Label.new()
	name_lbl.position = Vector2(20, 4)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COLOR_LABEL)
	name_lbl.name = "InstName"
	add_child(name_lbl)
	_labels.append(name_lbl)

	# Fields
	for i in range(FIELD_COUNT):
		var y := (i + 1) * ROW_HEIGHT + 20

		# Field name
		var lbl := Label.new()
		lbl.position = Vector2(20, y)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		lbl.add_theme_color_override("font_color", COLOR_TEXT)
		lbl.text = FIELD_NAMES[i]
		add_child(lbl)

		# Value label
		var val_lbl := Label.new()
		val_lbl.position = Vector2(150, y)
		val_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		val_lbl.add_theme_color_override("font_color", COLOR_VALUE)
		add_child(val_lbl)
		_labels.append(val_lbl)

		# Bar background
		var bar_bg := ColorRect.new()
		bar_bg.position = Vector2(280, y + 2)
		bar_bg.size = Vector2(BAR_WIDTH, 12)
		bar_bg.color = COLOR_BAR_BG
		add_child(bar_bg)

		# Bar foreground
		var bar_fg := ColorRect.new()
		bar_fg.position = Vector2(280, y + 2)
		bar_fg.size = Vector2(0, 12)
		bar_fg.color = COLOR_BAR_FG
		add_child(bar_fg)
		_bars.append(bar_fg)

func update_display() -> void:
	var inst: Instrument = SongManager.song.get_instrument(current_instrument)

	# Header
	_labels[0].text = "Instrument %02d: %s" % [current_instrument, inst.name]
	_labels[0].add_theme_color_override("font_color", COLOR_LABEL)

	# Field values
	var values := _get_field_values(inst)
	for i in range(FIELD_COUNT):
		var idx := i + 1
		if idx >= _labels.size():
			break

		# Highlight cursor
		_labels[idx].add_theme_color_override("font_color",
			COLOR_CURSOR if i == cursor_field else COLOR_VALUE)

		# Value text
		if i == 0:
			_labels[idx].text = CT.WAVEFORM_NAMES[inst.waveform]
		else:
			_labels[idx].text = str(values[i])

		# Update bar
		if i < _bars.size():
			var max_val := _get_field_max(i)
			if max_val > 0:
				_bars[i].size.x = float(values[i]) / float(max_val) * BAR_WIDTH
			_bars[i].color = COLOR_CURSOR if i == cursor_field else COLOR_BAR_FG

func _get_field_values(inst: Instrument) -> PackedInt32Array:
	return PackedInt32Array([
		inst.waveform,
		inst.attack,
		inst.decay,
		inst.sustain,
		inst.release,
		inst.vibrato_speed,
		inst.vibrato_depth,
		inst.pulse_width,
		inst.volume,
	])

func _get_field_max(field: int) -> int:
	if field == 0:
		return CT.Waveform.NOISE
	return 255

func _on_action(action: String) -> void:
	var inst: Instrument = SongManager.song.get_instrument(current_instrument)

	match action:
		"ui_up":
			cursor_field = (cursor_field - 1 + FIELD_COUNT) % FIELD_COUNT
		"ui_down":
			cursor_field = (cursor_field + 1) % FIELD_COUNT
		"action_a", "ui_right":
			_adjust_field(inst, 1)
		"action_b", "ui_left":
			_adjust_field(inst, -1)
		"action_l1":
			current_instrument = (current_instrument - 1 + CT.MAX_INSTRUMENTS) % CT.MAX_INSTRUMENTS
		"action_r1":
			current_instrument = (current_instrument + 1) % CT.MAX_INSTRUMENTS
		"select_up", "select_down":
			ScreenManager.pop_screen()
	update_display()

func _adjust_field(inst: Instrument, delta: int) -> void:
	var step := 1
	match cursor_field:
		0:  # Waveform
			inst.waveform = (inst.waveform + delta) % (CT.Waveform.NOISE + 1)
			if inst.waveform < 0:
				inst.waveform = CT.Waveform.NOISE
		1: inst.attack = clampi(inst.attack + delta * 5, 0, 255)
		2: inst.decay = clampi(inst.decay + delta * 5, 0, 255)
		3: inst.sustain = clampi(inst.sustain + delta * 5, 0, 255)
		4: inst.release = clampi(inst.release + delta * 5, 0, 255)
		5: inst.vibrato_speed = clampi(inst.vibrato_speed + delta, 0, 255)
		6: inst.vibrato_depth = clampi(inst.vibrato_depth + delta, 0, 255)
		7: inst.pulse_width = clampi(inst.pulse_width + delta * 8, 0, 255)
		8: inst.volume = clampi(inst.volume + delta * 8, 0, 255)
