## Phase-accumulation oscillator with 5 waveforms
## Float-based (0.0-1.0 phase) for Godot audio pipeline
class_name Oscillator

const CT = preload("res://scripts/constants.gd")

var phase: float = 0.0          ## 0.0-1.0
var increment: float = 0.0      ## freq / SAMPLE_RATE
var waveform: int = CT.Waveform.PULSE50
var pulse_width: float = 0.5    ## 0.0-1.0 (0.5 = 50% duty)
var noise_state: int = 0x7FFF   ## 15-bit LFSR state

func set_frequency(freq: float, sample_rate: int = CT.SAMPLE_RATE) -> void:
	increment = freq / float(sample_rate)

func set_note(note: int, note_table) -> void:
	var freq: float = note_table.get_frequency(note)
	increment = freq / float(CT.SAMPLE_RATE)

func reset() -> void:
	phase = 0.0
	noise_state = 0x7FFF

## Generate a single sample (-1.0 to 1.0)
func generate() -> float:
	phase = fmod(phase + increment, 1.0)
	if phase < 0.0:
		phase += 1.0

	match waveform:
		CT.Waveform.PULSE50:
			return -1.0 if phase >= 0.5 else 1.0
		CT.Waveform.PULSE25:
			return -1.0 if phase >= 0.25 else 1.0
		CT.Waveform.TRIANGLE:
			if phase < 0.5:
				return phase * 4.0 - 1.0
			else:
				return 1.0 - (phase - 0.5) * 4.0
		CT.Waveform.SAWTOOTH:
			return phase * 2.0 - 1.0
		CT.Waveform.NOISE:
			return _noise_step()
		_:
			return 0.0

## PWM pulse with variable duty cycle
func generate_pwm() -> float:
	phase = fmod(phase + increment, 1.0)
	if phase < 0.0:
		phase += 1.0
	return -1.0 if phase >= pulse_width else 1.0

## 15-bit LFSR noise generator
func _noise_step() -> float:
	var bit0: int = noise_state & 1
	var bit1: int = (noise_state >> 1) & 1
	var bit2: int = (noise_state >> 2) & 1
	# XOR feedback
	var new_bit: int = bit0 ^ bit1 ^ bit2
	noise_state = (noise_state >> 1) | (new_bit << 14)
	return -1.0 if (noise_state & 1) else 1.0
