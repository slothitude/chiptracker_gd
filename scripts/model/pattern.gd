## Pattern: 64 rows x 4 channels of Cell data
class_name Pattern

const CT = preload("res://scripts/constants.gd")
const Cell = preload("res://scripts/model/cell.gd")

var cells: Array  ## [row * NUM_CHANNELS + channel] = Cell

func _init() -> void:
	var size := CT.PATTERN_ROWS * CT.NUM_CHANNELS
	cells = []
	cells.resize(size)
	for i in range(size):
		cells[i] = Cell.new()

func get_cell(row: int, channel: int):
	return cells[row * CT.NUM_CHANNELS + channel]

func set_cell(row: int, channel: int, cell) -> void:
	cells[row * CT.NUM_CHANNELS + channel] = cell

func clear() -> void:
	for i in range(cells.size()):
		cells[i].clear()

## Check if the entire pattern is empty
func is_empty() -> bool:
	for cell in cells:
		if not cell.is_empty():
			return false
	return true

## Create a deep copy
func duplicate():
	var p = get_script().new()
	for i in range(cells.size()):
		p.cells[i] = cells[i].duplicate()
	return p
