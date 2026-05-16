## Order list: sequence of entries, each with a pattern index per channel
class_name OrderList

const CT = preload("res://scripts/constants.gd")

var entries: Array  ## Array of PackedByteArray (4 bytes per entry, one per channel)
var length: int = 1

func _init() -> void:
	entries = []
	entries.resize(CT.MAX_ORDER_ENTRIES)
	for i in range(CT.MAX_ORDER_ENTRIES):
		entries[i] = PackedByteArray()
		entries[i].resize(CT.NUM_CHANNELS)
		entries[i].fill(0)
	# Default: first entry points to patterns 0,1,2,3
	entries[0] = PackedByteArray([0, 1, 2, 3])
	length = 1

func get_entry(pos: int) -> PackedByteArray:
	if pos < 0 or pos >= length:
		return PackedByteArray([0, 0, 0, 0])
	return entries[pos]

func get_pattern_index(pos: int, channel: int) -> int:
	return get_entry(pos)[channel]

func set_pattern_index(pos: int, channel: int, index: int) -> void:
	if pos >= 0 and pos < CT.MAX_ORDER_ENTRIES:
		entries[pos][channel] = index

func insert_entry(pos: int) -> void:
	if length >= CT.MAX_ORDER_ENTRIES:
		return
	# Shift entries down
	for i in range(length, pos, -1):
		entries[i] = entries[i - 1].duplicate()
	# New entry: copy from previous or default
	if pos > 0:
		entries[pos] = entries[pos - 1].duplicate()
	else:
		entries[pos] = PackedByteArray([0, 0, 0, 0])
	length += 1

func remove_entry(pos: int) -> void:
	if length <= 1:
		return
	for i in range(pos, length - 1):
		entries[i] = entries[i + 1].duplicate()
	length -= 1
	entries[length] = PackedByteArray([0, 0, 0, 0])
