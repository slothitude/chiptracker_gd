## Autoload singleton: owns the Song instance, creates demo song, signals changes
extends Node

const CT = preload("res://scripts/constants.gd")
const Song = preload("res://scripts/model/song.gd")
const SongSerializer = preload("res://scripts/io/song_serializer.gd")

signal song_changed
signal song_loaded

var song  ## Song instance

func _ready() -> void:
	song = Song.new()
	_create_demo_song()

func new_song() -> void:
	song = Song.new()
	song_changed.emit()

func load_song(path: String) -> bool:
	var loaded = SongSerializer.load_song(path)
	if loaded == null:
		return false
	song = loaded
	song_loaded.emit()
	song_changed.emit()
	return true

func save_song(path: String) -> bool:
	return SongSerializer.save_song(song, path)

func _create_demo_song() -> void:
	song.name = "Demo"
	song.author = "ChipTracker"
	song.tempo = 150
	song.speed = 6

	# Order list: 4 positions cycling through patterns
	song.order_list.length = 4
	song.order_list.entries[0] = PackedByteArray([0, 1, 2, 3])
	song.order_list.entries[1] = PackedByteArray([4, 1, 2, 3])
	song.order_list.entries[2] = PackedByteArray([0, 5, 6, 3])
	song.order_list.entries[3] = PackedByteArray([4, 5, 6, 7])

	_write_melody(0, CT.Channel.PULSE1, [1, 3, 5, 6, 8, 10, 12, 13])
	_write_bass(1, CT.Channel.PULSE2, [1, 1, 1, 1, 8, 8, 8, 8, 1, 1, 1, 1, 6, 6, 8, 8])
	_write_arpeggio(2, CT.Channel.TRIANGLE, 1)
	_write_beat(3, CT.Channel.NOISE)
	_write_melody(4, CT.Channel.PULSE1, [13, 12, 10, 8, 6, 5, 3, 1])
	_write_bass(5, CT.Channel.PULSE2, [1, 1, 8, 8, 10, 10, 8, 8, 1, 1, 6, 6, 8, 8, 1, 1])
	_write_arpeggio(6, CT.Channel.TRIANGLE, 13)
	_write_beat(7, CT.Channel.NOISE)

func _write_melody(pat_idx: int, ch: int, notes: PackedInt32Array) -> void:
	var pat = song.patterns[pat_idx]
	var inst: int = ch + 1
	for i in range(mini(notes.size(), CT.PATTERN_ROWS)):
		if notes[i] > 0:
			pat.get_cell(i, ch).note = notes[i] + 24
			pat.get_cell(i, ch).instrument = inst

func _write_bass(pat_idx: int, ch: int, notes: PackedInt32Array) -> void:
	var pat = song.patterns[pat_idx]
	var inst: int = ch + 1
	for i in range(mini(notes.size(), CT.PATTERN_ROWS)):
		if notes[i] > 0:
			pat.get_cell(i, ch).note = notes[i] + 12
			pat.get_cell(i, ch).instrument = inst

func _write_arpeggio(pat_idx: int, ch: int, root: int) -> void:
	var pat = song.patterns[pat_idx]
	var inst: int = ch + 1
	var offsets := [0, 4, 7, 12, 7, 4, 0, -5]
	for i in range(CT.PATTERN_ROWS):
		if i % 2 == 0:
			var note_idx: int = root + 24 + offsets[(i / 2) % offsets.size()]
			if note_idx >= CT.NOTE_MIN and note_idx <= CT.NOTE_MAX:
				pat.get_cell(i, ch).note = note_idx
				pat.get_cell(i, ch).instrument = inst

func _write_beat(pat_idx: int, ch: int) -> void:
	var pat = song.patterns[pat_idx]
	var inst: int = ch + 1
	for i in range(CT.PATTERN_ROWS):
		if i % 4 == 0:
			pat.get_cell(i, ch).note = 37
			pat.get_cell(i, ch).instrument = inst
			pat.get_cell(i, ch).volume = 48
		elif i % 4 == 2:
			pat.get_cell(i, ch).note = 41
			pat.get_cell(i, ch).instrument = inst
			pat.get_cell(i, ch).volume = 32
