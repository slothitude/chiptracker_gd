## Synth channel: oscillator + envelope + effects per voice
class_name SynthChannel

const CT = preload("res://scripts/constants.gd")
const Oscillator = preload("res://scripts/audio/oscillator.gd")
const Envelope = preload("res://scripts/audio/envelope.gd")
const Effects = preload("res://scripts/audio/effects.gd")
const NoteTable = preload("res://scripts/note_table.gd")

var osc  ## Oscillator
var env  ## Envelope
var effects  ## Effects

var base_increment: float = 0.0
var current_increment: float = 0.0
var current_note: int = CT.NOTE_EMPTY
var channel_volume: float = 1.0
var note_active: bool = false

var _note_table  ## NoteTable

func _init(note_table) -> void:
	_note_table = note_table
	osc = Oscillator.new()
	env = Envelope.new()
	effects = Effects.new(note_table)

func note_on(note: int, volume: float = 1.0, instrument = null) -> void:
	current_note = note
	base_increment = _note_table.get_phase_increment(note)
	current_increment = base_increment

	if instrument != null:
		osc.waveform = instrument.waveform
		osc.pulse_width = float(instrument.pulse_width) / 255.0
		env.set_adsr(instrument.attack, instrument.decay, instrument.sustain, instrument.release)
		channel_volume = float(instrument.volume) / 255.0
	else:
		channel_volume = volume

	# Volume cell override
	if volume > 0.0 and volume <= 1.0:
		channel_volume = volume

	osc.reset()
	env.note_on()
	note_active = true

func note_off() -> void:
	env.note_off()
	note_active = false

func kill() -> void:
	env.kill()
	note_active = false
	current_note = CT.NOTE_EMPTY

## Set up tone portamento target (note on without retrigger)
func set_portamento(note: int, speed: int) -> void:
	effects.set_port_target(note)
	effects.set_effect(CT.Effect.TONE_PORTAMENTO, speed)
	current_note = note

## Advance effects once per sequencer tick
func process_tick() -> void:
	effects.process_tick()
	# Apply volume slide
	var vol_delta: float = effects.get_volume_delta()
	channel_volume = clampf(channel_volume + vol_delta, 0.0, 1.0)

## Generate a single sample
func generate() -> float:
	if not note_active and env.phase == CT.EnvPhase.OFF:
		return 0.0

	# Apply effects to get current increment
	current_increment = effects.apply_to_increment(base_increment, current_note)
	osc.increment = current_increment

	# Generate oscillator sample
	var sample: float
	if osc.waveform == CT.Waveform.PULSE50 or osc.waveform == CT.Waveform.PULSE25:
		sample = osc.generate_pwm()
	else:
		sample = osc.generate()

	# Apply envelope
	var env_level: float = env.tick()

	# Apply volume
	return sample * env_level * channel_volume
