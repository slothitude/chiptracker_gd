## Effects processor: arpeggio, portamento, vibrato, volume slide
class_name Effects

const CT = preload("res://scripts/constants.gd")
const NoteTable = preload("res://scripts/note_table.gd")

var effect_type: int = CT.Effect.NONE
var effect_value: int = 0

# Arpeggio state
var arp_phase: int = 0
var arp_base_note: int = 0

# Portamento state
var port_speed: float = 0.0
var port_target: float = 0.0  # target increment
var tone_port_active: bool = false

# Vibrato state
var vib_phase: int = 0
var vib_speed: int = 0
var vib_depth: int = 0

# Volume slide state
var vol_slide_up: float = 0.0
var vol_slide_down: float = 0.0

var _note_table  ## NoteTable

func _init(note_table) -> void:
	_note_table = note_table

func set_effect(type: int, value: int) -> void:
	effect_type = type
	effect_value = value

	# Initialize effect state
	var x: int = (value >> 4) & 0xF
	var y: int = value & 0xF

	match type:
		CT.Effect.ARPEGGIO:
			arp_phase = 0
		CT.Effect.PORTAMENTO_UP:
			port_speed = float(value) * 0.00001
		CT.Effect.PORTAMENTO_DOWN:
			port_speed = float(value) * 0.00001
		CT.Effect.TONE_PORTAMENTO:
			port_speed = float(value) * 0.00002
			tone_port_active = true
		CT.Effect.VIBRATO:
			vib_speed = x
			vib_depth = y
			vib_phase = 0
		CT.Effect.VOLUME_SLIDE:
			vol_slide_up = float(x) / 64.0
			vol_slide_down = float(y) / 64.0
		CT.Effect.SPEED:
			pass  # handled by sequencer

func clear() -> void:
	effect_type = CT.Effect.NONE
	effect_value = 0
	tone_port_active = false

## Called once per tick — advance arpeggio, vibrato phase
func process_tick() -> void:
	if effect_type == CT.Effect.ARPEGGIO:
		arp_phase = (arp_phase + 1) % 3
	if effect_type == CT.Effect.VIBRATO:
		vib_phase = (vib_phase + vib_speed) & 0x3F

## Apply effects to base increment, returns modified increment
func apply_to_increment(base_increment: float, base_note: int) -> float:
	var inc := base_increment

	match effect_type:
		CT.Effect.ARPEGGIO:
			var x := (effect_value >> 4) & 0xF
			var y := effect_value & 0xF
			var offset := 0
			if arp_phase == 1:
				offset = x
			elif arp_phase == 2:
				offset = y
			inc = _note_table.get_phase_increment(base_note + offset)

		CT.Effect.PORTAMENTO_UP:
			inc = base_increment + port_speed
			inc = minf(inc, 20000.0 / float(CT.SAMPLE_RATE))

		CT.Effect.PORTAMENTO_DOWN:
			inc = base_increment - port_speed
			inc = maxf(inc, 0.0)

		CT.Effect.TONE_PORTAMENTO:
			if inc < port_target:
				inc = minf(inc + port_speed, port_target)
			elif inc > port_target:
				inc = maxf(inc - port_speed, port_target)

		CT.Effect.VIBRATO:
			var mod_depth := float(vib_depth) / 64.0
			var vib_pos: float
			if vib_phase < 32:
				vib_pos = float(vib_phase) / 32.0
			else:
				vib_pos = 2.0 - float(vib_phase) / 32.0
			var mod := (vib_pos - 0.5) * mod_depth * inc * 2.0
			inc = base_increment + mod

	return inc

## Apply volume slide — returns volume delta per tick
func get_volume_delta() -> float:
	if effect_type == CT.Effect.VOLUME_SLIDE:
		return vol_slide_up - vol_slide_down
	return 0.0

## Set tone portamento target from a note
func set_port_target(note: int) -> void:
	port_target = _note_table.get_phase_increment(note)
