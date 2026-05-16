## Binary .ctk file reader/writer via FileAccess
## Format: little-endian, header(64) + global(8) + order list + instruments + patterns
class_name SongSerializer

const CT = preload("res://scripts/constants.gd")
const Song = preload("res://scripts/model/song.gd")
const Cell = preload("res://scripts/model/cell.gd")
const Instrument = preload("res://scripts/model/instrument.gd")
const Pattern = preload("res://scripts/model/pattern.gd")

const MAGIC := "CTK"
const VERSION := 1

static func save_song(song, path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SongSerializer: cannot open %s for writing" % path)
		return false

	# Header (64 bytes)
	f.store_pascal_string(MAGIC)       # 4 bytes (len + "CTK")
	f.store_8(VERSION)                  # version
	f.store_8(0)                        # reserved
	f.store_8(0)
	f.store_8(0)
	_pad_write(f, song.name, 32)        # song name
	_pad_write(f, song.author, 24)      # author

	# Global (8 bytes)
	f.store_16(song.tempo)
	f.store_8(song.speed)
	f.store_8(song.rows_per_beat)
	f.store_32(0)                       # reserved

	# Order list
	f.store_16(song.order_list.length)
	for i in range(song.order_list.length):
		for ch in range(CT.NUM_CHANNELS):
			f.store_8(song.order_list.entries[i][ch])

	# Instruments: count + records
	var inst_count := 0
	for i in range(CT.MAX_INSTRUMENTS):
		if not song.instruments[i].name.is_empty():
			inst_count = i + 1
	f.store_8(inst_count)
	for i in range(inst_count):
		_write_instrument(f, song.instruments[i])

	# Patterns: count + data
	var pat_count := 0
	for i in range(CT.MAX_PATTERNS):
		if not song.patterns[i].is_empty():
			pat_count = i + 1
	f.store_16(pat_count)
	for i in range(pat_count):
		f.store_8(i)
		_write_pattern(f, song.patterns[i])

	f.close()
	return true

static func load_song(path: String):
	if not FileAccess.file_exists(path):
		push_error("SongSerializer: file not found: %s" % path)
		return null

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SongSerializer: cannot open %s for reading" % path)
		return null

	# Header
	var magic_len := f.get_8()
	var magic := f.get_buffer(magic_len).get_string_from_ascii()
	if magic != MAGIC:
		push_error("SongSerializer: invalid magic: %s" % magic)
		f.close()
		return null

	var version := f.get_8()
	if version != VERSION:
		push_error("SongSerializer: unsupported version: %d" % version)
		f.close()
		return null

	f.get_8()  # reserved
	f.get_8()
	f.get_8()
	var song_name := _pad_read(f, 32)
	var author := _pad_read(f, 24)

	# Global
	var song := Song.new()
	song.name = song_name
	song.author = author
	song.tempo = f.get_16()
	song.speed = f.get_8()
	song.rows_per_beat = f.get_8()
	f.get_32()  # reserved

	# Order list
	var order_len := f.get_16()
	song.order_list.length = mini(order_len, CT.MAX_ORDER_ENTRIES)
	for i in range(song.order_list.length):
		for ch in range(CT.NUM_CHANNELS):
			song.order_list.entries[i][ch] = f.get_8()

	# Instruments
	var inst_count := f.get_8()
	for i in range(mini(inst_count, CT.MAX_INSTRUMENTS)):
		_read_instrument(f, song.instruments[i])

	# Patterns
	var pat_count := f.get_16()
	for _i in range(pat_count):
		var idx := f.get_8()
		if idx < CT.MAX_PATTERNS:
			_read_pattern(f, song.patterns[idx])
		else:
			# Skip unknown pattern
			f.get_buffer(CT.PATTERN_ROWS * CT.NUM_CHANNELS * 5)

	f.close()
	return song

static func _pad_write(f: FileAccess, s: String, size: int) -> void:
	var raw := s.to_ascii_buffer()
	var pad := maxi(0, size - raw.size())
	f.store_buffer(raw)
	f.store_buffer(PackedByteArray().resize(pad) if pad > 0 else PackedByteArray())

static func _pad_read(f: FileAccess, size: int) -> String:
	var buf := f.get_buffer(size)
	var end := buf.size()
	for i in range(buf.size()):
		if buf[i] == 0:
			end = i
			break
	return buf.slice(0, end).get_string_from_ascii()

static func _write_instrument(f: FileAccess, inst) -> void:
	_pad_write(f, inst.name, 16)
	f.store_8(inst.waveform)
	f.store_8(inst.attack)
	f.store_8(inst.decay)
	f.store_8(inst.sustain)
	f.store_8(inst.release)
	f.store_8(inst.vibrato_speed)
	f.store_8(inst.vibrato_depth)
	f.store_8(inst.sweep_speed)
	f.store_8(inst.sweep_dir)
	f.store_8(inst.pulse_width)
	f.store_8(inst.volume)
	# 5 bytes reserved to reach 32
	f.store_buffer(PackedByteArray([0, 0, 0, 0, 0]))

static func _read_instrument(f: FileAccess, inst) -> void:
	inst.name = _pad_read(f, 16)
	inst.waveform = f.get_8()
	inst.attack = f.get_8()
	inst.decay = f.get_8()
	inst.sustain = f.get_8()
	inst.release = f.get_8()
	inst.vibrato_speed = f.get_8()
	inst.vibrato_depth = f.get_8()
	inst.sweep_speed = f.get_8()
	inst.sweep_dir = f.get_8()
	inst.pulse_width = f.get_8()
	inst.volume = f.get_8()
	f.get_buffer(5)  # reserved

static func _write_pattern(f: FileAccess, pat) -> void:
	for row in range(CT.PATTERN_ROWS):
		for ch in range(CT.NUM_CHANNELS):
			var cell = pat.get_cell(row, ch)
			f.store_8(cell.note)
			f.store_8(cell.instrument)
			f.store_8(cell.volume)
			f.store_8(cell.effect_type)
			f.store_8(cell.effect_value)

static func _read_pattern(f: FileAccess, pat) -> void:
	for row in range(CT.PATTERN_ROWS):
		for ch in range(CT.NUM_CHANNELS):
			var cell = pat.get_cell(row, ch)
			cell.note = f.get_8()
			cell.instrument = f.get_8()
			cell.volume = f.get_8()
			cell.effect_type = f.get_8()
			cell.effect_value = f.get_8()
