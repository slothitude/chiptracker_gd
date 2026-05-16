## Audio manager autoload: AudioStreamGenerator + Synthesizer render loop
extends Node

const CT = preload("res://scripts/constants.gd")
const NoteTable = preload("res://scripts/note_table.gd")
const Synthesizer = preload("res://scripts/audio/synthesizer.gd")

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _synth  ## Synthesizer
var _note_table  ## NoteTable

func _ready() -> void:
	_note_table = NoteTable.new()
	_synth = Synthesizer.new(_note_table)

	_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = float(CT.SAMPLE_RATE)
	stream.buffer_length = 0.1
	_player.stream = stream
	_player.volume_db = 0.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

	# Pre-fill buffer with silence
	var silence := PackedVector2Array()
	silence.resize(CT.BUFFER_SAMPLES)
	silence.fill(Vector2.ZERO)
	_playback.push_buffer(silence)

func _process(_delta: float) -> void:
	if _playback == null:
		return

	var to_fill: int = _playback.get_frames_available()
	if to_fill <= 0:
		return

	var buffer: PackedVector2Array = _synth.render(to_fill)
	_playback.push_buffer(buffer)

func get_synth():
	return _synth

func get_note_table():
	return _note_table
