## A single cell in a pattern (note + instrument + volume + effect)
## 5 bytes in .ctk format
class_name Cell

const CT = preload("res://scripts/constants.gd")

var note: int = CT.NOTE_EMPTY        ## 0=empty, 1-96=C-0..B-7, 127=note-off
var instrument: int = CT.INST_NONE   ## 0=none, 1-63
var volume: int = 0                   ## 0-64 (0 = use instrument default)
var effect_type: int = CT.Effect.NONE ## 0x0-0xF
var effect_value: int = 0             ## 0x00-0xFF

func _init(p_note: int = CT.NOTE_EMPTY, p_inst: int = CT.INST_NONE,
		   p_vol: int = 0, p_eff_type: int = 0, p_eff_val: int = 0) -> void:
	note = p_note
	instrument = p_inst
	volume = p_vol
	effect_type = p_eff_type
	effect_value = p_eff_val

func is_empty() -> bool:
	return note == CT.NOTE_EMPTY and instrument == CT.INST_NONE and \
		volume == 0 and effect_type == 0 and effect_value == 0

func clear() -> void:
	note = CT.NOTE_EMPTY
	instrument = CT.INST_NONE
	volume = 0
	effect_type = 0
	effect_value = 0

func duplicate():
	var c = get_script().new()
	c.note = note
	c.instrument = instrument
	c.volume = volume
	c.effect_type = effect_type
	c.effect_value = effect_value
	return c

## Format cell for display in phrase screen
func format_note() -> String:
	return CT.note_name(note)

func format_instrument() -> String:
	if instrument == CT.INST_NONE:
		return ".."
	return "%02d" % instrument

func format_volume() -> String:
	if volume == 0:
		return ".."
	return "%02d" % volume

func format_effect() -> String:
	if effect_type == 0 and effect_value == 0:
		return "..."
	return CT.effect_char(effect_type) + "%02X" % effect_value
