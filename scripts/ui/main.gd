## Main scene root — sets up header/content/footer layout + wires singletons
extends Control

const CT = preload("res://scripts/constants.gd")

var header: Panel
var content: Control
var footer: Panel
var header_label: Label
var footer_label: Label

func _ready() -> void:
	# Wire sequencer to song + synth
	Sequencer.setup(SongManager.song, AudioManager.get_synth())

	# Header panel
	var header_panel := Panel.new()
	header_panel.name = "Header"
	header_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header_panel.set_deferred("size", Vector2(CT.SCREEN_W, 16))
	add_child(header_panel)

	var hlabel := Label.new()
	hlabel.name = "HeaderLabel"
	hlabel.position = Vector2(4, 3)
	hlabel.add_theme_font_size_override("font_size", 10)
	hlabel.text = "CHIPTRACKER"
	header_panel.add_child(hlabel)

	# Content container
	var content_container := Control.new()
	content_container.name = "ContentContainer"
	content_container.position = Vector2(0, 16)
	content_container.size = Vector2(CT.SCREEN_W, CT.SCREEN_H - 32)
	add_child(content_container)

	# Footer panel
	var footer_panel := Panel.new()
	footer_panel.name = "Footer"
	footer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.set_deferred("size", Vector2(CT.SCREEN_W, 16))
	add_child(footer_panel)

	var flabel := Label.new()
	flabel.name = "FooterLabel"
	flabel.position = Vector2(4, 3)
	flabel.add_theme_font_size_override("font_size", 10)
	flabel.text = "OCT:4  INST:01  BPM:150  SPD:6"
	footer_panel.add_child(flabel)

	# Store references
	header = header_panel
	footer = footer_panel
	content = content_container
	header_label = hlabel
	footer_label = flabel

	# Setup screen manager and push phrase screen (load at runtime)
	ScreenManager.setup(content_container)
	var phrase_script = load("res://scripts/ui/phrase_screen.gd")
	var phrase_screen = phrase_script.new()
	ScreenManager.push_screen(phrase_screen)

func _process(delta: float) -> void:
	# Feed sequencer timing into audio pipeline
	var sample_count: int = int(float(CT.SAMPLE_RATE) * delta)
	Sequencer.process_audio(sample_count)

	# Update header with playback state
	if Sequencer.state == Sequencer.State.PLAYING:
		header_label.text = "CHIPTRACKER [PLAYING POS:%d ROW:%02d]" % [Sequencer.current_position, Sequencer.current_row]
	else:
		header_label.text = "CHIPTRACKER [STOPPED]"
