## ADSR envelope state machine — returns 0.0-1.0
class_name Envelope

const CT = preload("res://scripts/constants.gd")

var phase: int = CT.EnvPhase.OFF
var level: float = 0.0
var counter: int = 0

var attack: int = 0      ## 0-255
var decay: int = 0       ## 0-255
var sustain: float = 1.0 ## 0.0-1.0
var release: int = 0     ## 0-255

var _release_level: float = 0.0

func set_adsr(p_attack: int, p_decay: int, p_sustain: int, p_release: int) -> void:
	attack = p_attack
	decay = p_decay
	sustain = float(p_sustain) / 255.0
	release = p_release

func note_on() -> void:
	phase = CT.EnvPhase.ATTACK
	counter = 0
	level = 0.0

func note_off() -> void:
	if phase != CT.EnvPhase.OFF and phase != CT.EnvPhase.RELEASE:
		_release_level = level
		phase = CT.EnvPhase.RELEASE
		counter = 0

func kill() -> void:
	phase = CT.EnvPhase.OFF
	level = 0.0
	counter = 0

## Advance envelope by one sample, return current level (0.0-1.0)
func tick() -> float:
	if phase == CT.EnvPhase.OFF:
		return 0.0

	var rate_scale := 40  # samples per unit
	counter += 1

	match phase:
		CT.EnvPhase.ATTACK:
			var attack_len := attack * rate_scale
			if attack_len == 0:
				level = 1.0
				_enter_decay()
			else:
				level = float(counter) / float(attack_len)
				if counter >= attack_len:
					level = 1.0
					_enter_decay()

		CT.EnvPhase.DECAY:
			var decay_len := decay * rate_scale
			if decay_len == 0:
				level = sustain
				phase = CT.EnvPhase.SUSTAIN
				counter = 0
			else:
				var decay_range := 1.0 - sustain
				level = 1.0 - (float(counter) * decay_range / float(decay_len))
				if counter >= decay_len:
					level = sustain
					phase = CT.EnvPhase.SUSTAIN
					counter = 0

		CT.EnvPhase.SUSTAIN:
			level = sustain

		CT.EnvPhase.RELEASE:
			var rel_len := release * rate_scale
			if rel_len == 0:
				level = 0.0
				phase = CT.EnvPhase.OFF
			else:
				level = _release_level * (1.0 - float(counter) / float(rel_len))
				if counter >= rel_len:
					level = 0.0
					phase = CT.EnvPhase.OFF

	return level

func _enter_decay() -> void:
	phase = CT.EnvPhase.DECAY
	counter = 0
