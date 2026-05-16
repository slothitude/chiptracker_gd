## Song: the top-level data container
class_name Song

const CT = preload("res://scripts/constants.gd")
const OrderList = preload("res://scripts/model/order_list.gd")
const Pattern = preload("res://scripts/model/pattern.gd")
const Instrument = preload("res://scripts/model/instrument.gd")

var name: String = "Untitled"
var author: String = ""
var tempo: int = 150       ## 32-255 BPM
var speed: int = 6         ## 1-31 ticks per row
var rows_per_beat: int = 4 ## 1-32
var order_list  ## OrderList
var patterns: Array        ## Array of Pattern (MAX_PATTERNS)
var instruments: Array     ## Array of Instrument (MAX_INSTRUMENTS)

func _init() -> void:
	order_list = OrderList.new()

	patterns = []
	patterns.resize(CT.MAX_PATTERNS)
	for i in range(CT.MAX_PATTERNS):
		patterns[i] = Pattern.new()

	instruments = []
	instruments.resize(CT.MAX_INSTRUMENTS)
	for i in range(CT.MAX_INSTRUMENTS):
		instruments[i] = Instrument.new("Inst %02d" % i)
	# Default instrument waveforms per NES channel style
	instruments[0].waveform = CT.Waveform.PULSE50
	instruments[0].name = "Pulse 50%"
	instruments[1].waveform = CT.Waveform.PULSE25
	instruments[1].name = "Pulse 25%"
	instruments[2].waveform = CT.Waveform.TRIANGLE
	instruments[2].name = "Triangle"
	instruments[3].waveform = CT.Waveform.NOISE
	instruments[3].name = "Noise"

func get_pattern(index: int):
	if index < 0 or index >= CT.MAX_PATTERNS:
		return patterns[0]
	return patterns[index]

func get_instrument(index: int):
	if index < 0 or index >= CT.MAX_INSTRUMENTS:
		return instruments[0]
	return instruments[index]
