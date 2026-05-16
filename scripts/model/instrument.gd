## Instrument definition (32 bytes in .ctk format)
class_name Instrument

const CT = preload("res://scripts/constants.gd")

var name: String = ""
var waveform: int = CT.Waveform.PULSE50
var attack: int = 0        ## 0-255
var decay: int = 0         ## 0-255
var sustain: int = 255     ## 0-255 (level)
var release: int = 0       ## 0-255
var vibrato_speed: int = 0 ## 0 = off
var vibrato_depth: int = 0 ## 0 = off
var sweep_speed: int = 0   ## 0 = off
var sweep_dir: int = 0     ## -1 down, 0 off, +1 up
var pulse_width: int = 128 ## 0-255 (128 = 50% duty)
var volume: int = 255      ## 0-255

func _init(p_name: String = "", p_wave: int = CT.Waveform.PULSE50) -> void:
	name = p_name
	waveform = p_wave

func duplicate():
	var inst = get_script().new()
	inst.name = name
	inst.waveform = waveform
	inst.attack = attack
	inst.decay = decay
	inst.sustain = sustain
	inst.release = release
	inst.vibrato_speed = vibrato_speed
	inst.vibrato_depth = vibrato_depth
	inst.sweep_speed = sweep_speed
	inst.sweep_dir = sweep_dir
	inst.pulse_width = pulse_width
	inst.volume = volume
	return inst
