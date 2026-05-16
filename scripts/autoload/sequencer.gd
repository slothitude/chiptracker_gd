## Sequencer autoload: playback state machine (play/stop, tick/row advance)
extends Node

const CT = preload("res://scripts/constants.gd")
const Song = preload("res://scripts/model/song.gd")
const Pattern = preload("res://scripts/model/pattern.gd")
const Cell = preload("res://scripts/model/cell.gd")
const Instrument = preload("res://scripts/model/instrument.gd")
const SynthChannel = preload("res://scripts/audio/synth_channel.gd")

signal playback_started
signal playback_stopped
signal row_advanced(row: int)

enum State {
	STOPPED,
	PLAYING,
}

var state: int = State.STOPPED
var current_position: int = 0   ## Order list position
var current_row: int = 0        ## Current row in pattern (0-63)
var current_tick: int = 0       ## Current tick within row (0..speed-1)
var sample_counter: float = 0.0

var _song  ## Song
var _synth  ## Synthesizer

func _ready() -> void:
	pass  # initialized by main scene

func setup(song, synth) -> void:
	_song = song
	_synth = synth

func start_playback() -> void:
	if state == State.PLAYING:
		return
	state = State.PLAYING
	current_position = 0
	current_row = 0
	current_tick = 0
	sample_counter = 0.0
	_trigger_current_row()
	playback_started.emit()

func stop_playback() -> void:
	if state == State.STOPPED:
		return
	state = State.STOPPED
	if _synth:
		_synth.silence()
	playback_stopped.emit()

func toggle_playback() -> void:
	if state == State.PLAYING:
		stop_playback()
	else:
		start_playback()

## Called from main scene each process frame
func process_audio(sample_count: int) -> void:
	if state != State.PLAYING or _song == null or _synth == null:
		return

	var samples_per_beat: float = float(CT.SAMPLE_RATE * 60) / float(_song.tempo)
	var samples_per_row: float = samples_per_beat / float(_song.rows_per_beat)
	var samples_per_tick: float = samples_per_row / float(_song.speed)

	sample_counter += float(sample_count)
	while sample_counter >= samples_per_tick:
		sample_counter -= samples_per_tick
		current_tick += 1
		if current_tick >= _song.speed:
			current_tick = 0
			_advance_row()
		else:
			_process_tick()

func _advance_row() -> void:
	current_row += 1
	if current_row >= CT.PATTERN_ROWS:
		current_row = 0
		current_position += 1
		if current_position >= _song.order_list.length:
			current_position = 0
	_trigger_current_row()
	row_advanced.emit(current_row)

func _process_tick() -> void:
	if _synth:
		_synth.process_tick()

func _trigger_current_row() -> void:
	if _song == null or _synth == null:
		return

	var order_entry: PackedByteArray = _song.order_list.get_entry(current_position)

	for ch in range(CT.NUM_CHANNELS):
		var pat_idx: int = order_entry[ch]
		var pat = _song.get_pattern(pat_idx)
		var cell = pat.get_cell(current_row, ch)

		# Handle instrument change
		var inst = null
		if cell.instrument > 0 and cell.instrument < CT.MAX_INSTRUMENTS:
			inst = _song.get_instrument(cell.instrument)

		# Handle note
		if cell.note == CT.NOTE_OFF:
			_synth.channels[ch].note_off()
		elif cell.note >= CT.NOTE_MIN and cell.note <= CT.NOTE_MAX:
			var vol: float = 1.0
			if inst:
				vol = float(inst.volume) / 255.0
			if cell.volume > 0:
				vol = float(cell.volume) / float(CT.VOLUME_MAX)
			_synth.trigger_note(ch, cell.note, inst, vol)

		# Handle effect
		if cell.effect_type != 0:
			_synth.set_effect(ch, cell.effect_type, cell.effect_value)
		else:
			_synth.channels[ch].effects.clear()
