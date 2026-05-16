## 4-channel mixer — outputs float stereo via PackedVector2Array
class_name Synthesizer

const CT = preload("res://scripts/constants.gd")
const SynthChannel = preload("res://scripts/audio/synth_channel.gd")

var channels: Array = []  ## Array of SynthChannel
var master_volume: float = 0.5
var _note_table  ## NoteTable

func _init(note_table) -> void:
	_note_table = note_table
	for i in range(CT.NUM_CHANNELS):
		var ch := SynthChannel.new(note_table)
		# Default NES-style waveforms
		match i:
			0: ch.osc.waveform = CT.Waveform.PULSE50
			1: ch.osc.waveform = CT.Waveform.PULSE25
			2: ch.osc.waveform = CT.Waveform.TRIANGLE
			3: ch.osc.waveform = CT.Waveform.NOISE
		channels.append(ch)

## Trigger a note on a channel
func trigger_note(channel: int, note: int, instrument = null, volume: float = 1.0) -> void:
	if channel < 0 or channel >= CT.NUM_CHANNELS:
		return
	if note == CT.NOTE_OFF:
		channels[channel].note_off()
	elif note >= CT.NOTE_MIN and note <= CT.NOTE_MAX:
		channels[channel].note_on(note, volume, instrument)

## Set effect on a channel
func set_effect(channel: int, effect_type: int, effect_value: int) -> void:
	if channel < 0 or channel >= CT.NUM_CHANNELS:
		return
	channels[channel].effects.set_effect(effect_type, effect_value)

## Advance all channels by one tick
func process_tick() -> void:
	for ch in channels:
		ch.process_tick()

## Render audio into a PackedVector2Array (stereo float)
func render(frame_count: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(frame_count)

	for i in range(frame_count):
		var mix: float = 0.0
		for ch in channels:
			mix += ch.generate()

		# Average across channels and apply master volume
		mix = mix / float(CT.NUM_CHANNELS) * master_volume

		# Hard clip
		mix = clampf(mix, -1.0, 1.0)

		# Mono → stereo
		buffer[i] = Vector2(mix, mix)

	return buffer

## Kill all channels
func silence() -> void:
	for ch in channels:
		ch.kill()
