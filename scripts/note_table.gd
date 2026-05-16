## Precomputed frequency table for notes 1-96 (C-0 to B-7)
## A4 (note 58) = 440 Hz, 12-TET tuning
class_name NoteTable

const CT = preload("res://scripts/constants.gd")

## Frequency for each note index (1-based, so index 0 = note 1 = C-0)
var frequencies: PackedFloat64Array

func _init() -> void:
	frequencies = PackedFloat64Array()
	frequencies.resize(96)
	for i in range(96):
		var note_num: int = i + 1  # 1-based
		# MIDI-like: note 1 = C-0, note 58 = A-4
		# Semitones from A4: note_num - 58
		var semitones_from_a4: float = float(note_num) - 58.0
		frequencies[i] = 440.0 * pow(2.0, semitones_from_a4 / 12.0)

## Get frequency for note value (1-96). Returns 0.0 for empty/off.
func get_frequency(note: int) -> float:
	if note < 1 or note > 96:
		return 0.0
	return frequencies[note - 1]

## Get phase increment for a note at given sample rate
func get_phase_increment(note: int, sample_rate: int = CT.SAMPLE_RATE) -> float:
	var freq: float = get_frequency(note)
	if freq <= 0.0:
		return 0.0
	return freq / float(sample_rate)
