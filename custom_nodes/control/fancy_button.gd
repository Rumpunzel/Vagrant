@tool
class_name FancyButton
extends DisplayButton

signal hover_status_changed(hovered: bool)

@export_placeholder("Only shown if there is no icon") var glyph: String:
	set(new_glyph):
		glyph = new_glyph
		_glyph_text.text = glyph

@export_group("Glyph")
@export var glyph_size: Vector2 = Vector2(24.0, 24.0):
	set(new_size):
		glyph_size = new_size
		_fancy_glyph.custom_minimum_size = glyph_size
		_glyph_icon.custom_minimum_size.y = glyph_size.y
@export var glyph_margin_left: int = 0:
	set(new_margin_left):
		glyph_margin_left = new_margin_left
		_fancy_glyph.add_theme_constant_override("margin_left", glyph_margin_left)
@export var glyph_margin_top: int = 0:
	set(new_margin_top):
		glyph_margin_top = new_margin_top
		_fancy_glyph.add_theme_constant_override("margin_top", new_margin_top)
@export var glyph_margin_right: int = 0:
	set(new_margin_right):
		glyph_margin_right = new_margin_right
		_fancy_glyph.add_theme_constant_override("margin_right", new_margin_right)
@export var glyph_margin_bottom: int = 0:
	set(new_margin_bottom):
		glyph_margin_bottom = new_margin_bottom
		_fancy_glyph.add_theme_constant_override("margin_bottom", new_margin_bottom)

@export_group("Audio")
@export var stream: AudioStream:
	get: return _audio_stream_player.stream
	set(new_stream): _audio_stream_player.stream = new_stream
@export_range(-80.0, 24.0, 0.1, "or_less", "or_greater", "suffix:dB") var volume_db: float:
	get: return _audio_stream_player.volume_db
	set(new_volume_db): _audio_stream_player.volume_db = new_volume_db
@export_range(0.01, 4.0, 0.1, "or_greater", "suffix:pct") var pitch_scale: float = 1.0:
	get: return _audio_stream_player.pitch_scale
	set(new_pitch_scale): _audio_stream_player.pitch_scale = new_pitch_scale

@export_group("Layout")
@export var margin_left: int = 4:
	set(new_margin_left):
		margin_left = new_margin_left
		_flex_container.add_theme_constant_override("margin_left", new_margin_left)
@export var margin_top: int = 4:
	set(new_margin_top):
		margin_top = new_margin_top
		_flex_container.add_theme_constant_override("margin_left", margin_top)
@export var margin_right: int = 4:
	set(new_margin_right):
		margin_right = new_margin_right
		_flex_container.add_theme_constant_override("margin_left", margin_right)
@export var margin_bottom: int = 4:
	set(new_margin_bottom):
		margin_bottom = new_margin_bottom
		_flex_container.add_theme_constant_override("margin_left", margin_bottom)
@export var flex_alignment: BoxContainer.AlignmentMode = BoxContainer.AlignmentMode.ALIGNMENT_END:
	set(new_flex_alignment):
		flex_alignment = new_flex_alignment
		_flex_container.alignment = flex_alignment
@export var direction: FlexContainer.Direction:
	get: return _flex_container.direction
	set(new_direction): _flex_container.direction = new_direction

var _hovered: bool = false:
	set(new_status):
		if new_status == _hovered: return
		_hovered = new_status
		hover_status_changed.emit(_hovered)

var _audio_stream_player: AudioStreamPlayer
var _fancy_panel: PanelContainer
var _flex_container: FlexContainer
var _fancy_glyph: MarginContainer
var _glyph_icon: TextureRect
var _glyph_text: RichTextLabel
var _fancy_text: RichTextLabel

func _init() -> void:
	## Audio
	_setup_audio_stream_player()
	## Layout
	_setup_fancy_panel()
	_setup_flex_container()
	## Fancy Glyph
	_setup_fancy_glyph()
	_setup_glyph_icon()
	_setup_glyp_text()
	## Fancy Text
	_setup_fancy_text()
	## Fancy Button
	set(&"alignment", alignment)
	set(&"icon", icon)
	set(&"text", text)
	button_down.connect(_update_style)
	button_up.connect(_update_style)
	pressed.connect(grab_focus)
	focus_entered.connect(_update_style)
	focus_exited.connect(_update_style)
	mouse_entered.connect(func() -> void: _hovered = true; _update_style())
	mouse_exited.connect(func() -> void: _hovered = false; _update_style())
	style_changed.connect(_update_style)
	if not is_node_ready(): await ready
	_update_style()

func _setup_audio_stream_player() -> void:
	assert(not _audio_stream_player)
	_audio_stream_player = AudioStreamPlayer.new()
	_audio_stream_player.stream = stream
	_audio_stream_player.volume_db = volume_db
	_audio_stream_player.pitch_scale = pitch_scale
	_audio_stream_player.bus = &"SFX"
	add_child(_audio_stream_player, true, Node.INTERNAL_MODE_BACK)
	pressed.connect(_audio_stream_player.play)

func _setup_fancy_panel() -> void:
	assert(not _fancy_panel)
	_fancy_panel = PanelContainer.new()
	_fancy_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fancy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fancy_panel, true, Node.INTERNAL_MODE_BACK)
	_fancy_panel.minimum_size_changed.connect(func() -> void: custom_minimum_size = _fancy_panel.get_minimum_size())

func _setup_flex_container() -> void:
	assert(not _flex_container)
	_flex_container = FlexContainer.new()
	_flex_container.fill = false
	_flex_container.alignment = flex_alignment
	_flex_container.direction = direction
	_flex_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flex_container.add_theme_constant_override("margin_left", margin_left)
	_flex_container.add_theme_constant_override("margin_top", margin_top)
	_flex_container.add_theme_constant_override("margin_right", margin_right)
	_flex_container.add_theme_constant_override("margin_bottom", margin_bottom)
	_fancy_panel.add_child(_flex_container)

func _setup_fancy_glyph() -> void:
	assert(not _fancy_glyph)
	_fancy_glyph = MarginContainer.new()
	_fancy_glyph.name = "Glyph"
	_fancy_glyph.custom_minimum_size = glyph_size
	_fancy_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fancy_glyph.add_theme_constant_override("margin_left", glyph_margin_left)
	_fancy_glyph.add_theme_constant_override("margin_top", glyph_margin_top)
	_fancy_glyph.add_theme_constant_override("margin_right", glyph_margin_right)
	_fancy_glyph.add_theme_constant_override("margin_bottom", glyph_margin_bottom)
	_flex_container.add(_fancy_glyph)

func _setup_glyph_icon() -> void:
	assert(not _glyph_icon)
	_glyph_icon = TextureRect.new()
	_glyph_icon.name = "GlyphIcon"
	_glyph_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_glyph_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_glyph_icon.size_flags_horizontal = Control.SIZE_SHRINK_END
	_glyph_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_glyph_icon.custom_minimum_size.y = glyph_size.y
	_glyph_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fancy_glyph.add_child(_glyph_icon)

func _setup_glyp_text() -> void:
	_glyph_text = RichTextLabel.new()
	_glyph_text.name = "GlyphText"
	_glyph_text.bbcode_enabled = true
	_glyph_text.text = glyph
	_glyph_text.scroll_active = false
	_glyph_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_glyph_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph_text.custom_minimum_size = glyph_size
	_glyph_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_glyph_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fancy_glyph.add_child(_glyph_text)

func _setup_fancy_text() -> void:
	assert(not _fancy_text)
	_fancy_text = RichTextLabel.new()
	_fancy_text.name = "Text"
	_fancy_text.bbcode_enabled = true
	_fancy_text.fit_content = true
	_fancy_text.scroll_active = false
	_fancy_text.autowrap_mode = autowrap_mode
	_fancy_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fancy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fancy_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flex_container.add(_fancy_text)

func _update_style() -> void:
	_fancy_panel.add_theme_stylebox_override("panel", _get_panel_style())
	_glyph_icon.modulate = _get_glyph_icon_color()
	_glyph_text.add_theme_color_override("default_color", _get_glyph_font_color())
	_fancy_text.add_theme_color_override("default_color", _get_text_color())

func _get_panel_style() -> StyleBox:
	if flat: return StyleBoxEmpty.new()
	var panel_style: StyleBox = get_theme_stylebox("normal")
	if disabled: panel_style = get_theme_stylebox("disabled")
	elif button_pressed:
		if _hovered: panel_style = get_theme_stylebox("hover_pressed")
		else: panel_style = get_theme_stylebox("pressed")
	elif _hovered: panel_style = get_theme_stylebox("hover")
	elif has_focus(): panel_style = get_theme_stylebox("focus")
	return panel_style

func _get_glyph_icon_color() -> Color:
	var glyph_color: Color = get_theme_color("icon_normal_color")
	if disabled: glyph_color = get_theme_color("icon_disabled_color")
	elif button_pressed:
		if _hovered: glyph_color = get_theme_color("icon_hover_pressed_color")
		else: glyph_color = get_theme_color("icon_pressed_color")
	elif _hovered: glyph_color = get_theme_color("icon_hover_color")
	elif has_focus(): glyph_color = get_theme_color("icon_focus_color")
	return glyph_color

func _get_glyph_font_color() -> Color:
	var glyph_color: Color = get_theme_color("font_color")
	if disabled: glyph_color = get_theme_color("font_disabled_color")
	elif button_pressed:
		if _hovered: glyph_color = get_theme_color("font_hover_pressed_color")
		else: glyph_color = get_theme_color("font_pressed_color")
	elif _hovered: glyph_color = get_theme_color("font_hover_color")
	elif has_focus(): glyph_color = get_theme_color("font_focus_color")
	return glyph_color

func _get_text_color() -> Color:
	var text_color: Color = get_theme_color("font_color")
	if disabled: text_color = get_theme_color("font_disabled_color")
	elif button_pressed:
		if _hovered: text_color = get_theme_color("font_hover_pressed_color")
		else: text_color = get_theme_color("font_pressed_color")
	elif _hovered: text_color = get_theme_color("font_hover_color")
	elif has_focus(): text_color = get_theme_color("font_focus_color")
	return text_color

func _get(property: StringName) -> Variant:
	match property:
		&"icon": return _glyph_icon.texture
		&"text": return _fancy_text.text
	return null

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"alignment":
			alignment = value
			match alignment:
				HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_FILL: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				HORIZONTAL_ALIGNMENT_CENTER: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				HORIZONTAL_ALIGNMENT_RIGHT: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			return true
		&"autowrap_mode":
			autowrap_mode = value
			_fancy_text.autowrap_mode = autowrap_mode
			return true
		&"disabled":
			disabled = value
			_update_style()
			return true
		&"icon":
			_glyph_icon.texture = value
			_glyph_icon.visible = value != null
			_glyph_text.visible = value == null
			icon = null
			return true
		&"text":
			_fancy_text.text = value
			text = ""
			return true
	return false
