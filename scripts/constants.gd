## ChipTracker constants and enums
class_name CT

## Display
const SCREEN_W := 640
const SCREEN_H := 480
const COLS := 80
const ROWS := 60

## Audio
const SAMPLE_RATE := 44100
const BUFFER_SAMPLES := 1024
const NUM_CHANNELS := 4

## Sequencer limits
const MAX_PATTERNS := 256
const MAX_INSTRUMENTS := 64
const MAX_ORDER_ENTRIES := 256
const PATTERN_ROWS := 64

## Cell
const NOTE_EMPTY := 0
const NOTE_OFF := 127
const NOTE_MIN := 1
const NOTE_MAX := 96
const VOLUME_MAX := 64
const INST_NONE := 0

## Waveform types
enum Waveform {
	PULSE50 = 0,
	PULSE25 = 1,
	TRIANGLE = 2,
	SAWTOOTH = 3,
	NOISE = 4,
}

## ADSR envelope phases
enum EnvPhase {
	OFF = 0,
	ATTACK = 1,
	DECAY = 2,
	SUSTAIN = 3,
	RELEASE = 4,
}

## Effect types (hex values matching tracker convention)
enum Effect {
	NONE = 0x0,
	ARPEGGIO = 0x0,
	PORTAMENTO_UP = 0x1,
	PORTAMENTO_DOWN = 0x2,
	TONE_PORTAMENTO = 0x3,
	VIBRATO = 0x4,
	TONE_PORT_VOL_SLIDE = 0x5,
	VIBRATO_VOL_SLIDE = 0x6,
	TREMOLO = 0x7,
	PANNING = 0x8,
	VOLUME_SLIDE = 0x9,
	POSITION_JUMP = 0xB,
	PATTERN_BREAK = 0xD,
	SPEED = 0xF,
}

## Channel types (NES-style)
enum Channel {
	PULSE1 = 0,
	PULSE2 = 1,
	TRIANGLE = 2,
	NOISE = 3,
}

## Note name strings for display
const NOTE_NAMES: PackedStringArray = [
	"C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"
]

## Note name for a given note value (1-96)
static func note_name(note: int) -> String:
	if note == NOTE_EMPTY:
		return "---"
	if note == NOTE_OFF:
		return "OFF"
	var octave: int = (note - 1) / 12
	var semitone: int = (note - 1) % 12
	return NOTE_NAMES[semitone] + str(octave)

## Effect type to hex char
static func effect_char(eff: int) -> String:
	if eff <= 9:
		return str(eff)
	return char(65 + eff - 10)

## Waveform display names
const WAVEFORM_NAMES: PackedStringArray = [
	"Pulse50", "Pulse25", "Triangle", "Sawtooth", "Noise"
]

## Channel display names
const CHANNEL_NAMES: PackedStringArray = [
	"PU1", "PU2", "TRI", "NSE"
]
