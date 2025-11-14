@tool
class_name FancyButton
extends DisplayButton

signal hover_status_changed(hovered: bool)

@export var glyph: String :
	set(new_glyph):
		glyph = new_glyph
		_glyph_text.text = glyph

@export_group("Glyph")
@export var _glyph_size: Vector2 = Vector2(32.0, 23.0)
@export var _glyph_margin_left: int = 0
@export var _glyph_margin_top: int = 0
@export var _glyph_margin_right: int = 0
@export var _glyph_margin_bottom: int = 0

@export_group("Audio")
@export var _stream: AudioStream
@export_range(-80.0, 24.0, 0.1, "or_less", "or_greater", "suffix:dB") var _volume_db: float = 0.0
@export_range(0.01, 4.0, 0.1, "or_greater", "suffix:pct") var _pitch_scale: float = 1.0

@export_group("Layout")
@export var _margin_left: int = 4
@export var _margin_top: int = 4
@export var _margin_right: int = 4
@export var _margin_bottom: int = 4
@export var _alignment: BoxContainer.AlignmentMode = BoxContainer.AlignmentMode.ALIGNMENT_END
@export var _direction: FlexContainer.Direction = FlexContainer.Direction.LEFT_TO_RIGHT

var _fancy_panel: PanelContainer
var _fancy_glyph: MarginContainer
var _glyph_icon: TextureRect
var _glyph_text: RichTextLabel
var _fancy_text: RichTextLabel

var _hovered: bool = false :
	set(new_status):
		if new_status == _hovered: return
		_hovered = new_status
		hover_status_changed.emit(_hovered)

func _init() -> void:
	## AudioStreamPlayer
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = _stream
	audio.volume_db = _volume_db
	audio.pitch_scale = _pitch_scale
	audio.bus = &"SFX"
	add_child(audio, true, Node.INTERNAL_MODE_BACK)
	pressed.connect(audio.play)
	## Fancy Panel
	_fancy_panel = PanelContainer.new()
	_fancy_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fancy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fancy_panel, true, Node.INTERNAL_MODE_BACK)
	_fancy_panel.minimum_size_changed.connect(func() -> void: custom_minimum_size = _fancy_panel.get_minimum_size())
	## FlexContainer
	var flex_container: FlexContainer = FlexContainer.new()
	flex_container.fill = false
	flex_container.alignment = _alignment
	flex_container.direction = _direction
	flex_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flex_container.add_theme_constant_override("margin_left", _margin_left)
	flex_container.add_theme_constant_override("margin_top", _margin_top)
	flex_container.add_theme_constant_override("margin_right", _margin_right)
	flex_container.add_theme_constant_override("margin_bottom", _margin_bottom)
	_fancy_panel.add_child(flex_container)
	## Fancy Glyph
	_fancy_glyph = MarginContainer.new()
	_fancy_glyph.name = "Glyph"
	_fancy_glyph.custom_minimum_size = _glyph_size
	_fancy_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fancy_glyph.add_theme_constant_override("margin_left", _glyph_margin_left)
	_fancy_glyph.add_theme_constant_override("margin_top", _glyph_margin_top)
	_fancy_glyph.add_theme_constant_override("margin_right", _glyph_margin_right)
	_fancy_glyph.add_theme_constant_override("margin_bottom", _glyph_margin_bottom)
	flex_container.add(_fancy_glyph)
	## Glyph Icon
	_glyph_icon = TextureRect.new()
	_glyph_icon.name = "GlyphIcon"
	_glyph_icon.texture = icon
	_glyph_icon.visible = icon != null
	_glyph_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_glyph_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_glyph_icon.size_flags_horizontal = Control.SIZE_SHRINK_END
	_glyph_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_glyph_icon.custom_minimum_size.y = _glyph_size.y
	_glyph_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph_icon.size = Vector2.ZERO
	_fancy_glyph.add_child(_glyph_icon)
	## Glyph Text
	_glyph_text = RichTextLabel.new()
	_glyph_text.name = "GlyphText"
	_glyph_text.visible = icon == null
	_glyph_text.bbcode_enabled = true
	_glyph_text.text = glyph
	_glyph_text.scroll_active = false
	_glyph_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_glyph_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph_text.custom_minimum_size = _glyph_size
	_glyph_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fancy_glyph.add_child(_glyph_text)
	## Fancy Text
	_fancy_text = RichTextLabel.new()
	_fancy_text.name = "Text"
	_fancy_text.bbcode_enabled = true
	_fancy_text.text = text
	_fancy_text.fit_content = true
	_fancy_text.scroll_active = false
	match alignment:
		HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_FILL: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		HORIZONTAL_ALIGNMENT_CENTER: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		HORIZONTAL_ALIGNMENT_RIGHT: _fancy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fancy_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fancy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fancy_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flex_container.add(_fancy_text)
	## Fancy Button
	clip_text = true
	expand_icon = true
	self_modulate = Color.TRANSPARENT
	button_down.connect(_update_style)
	button_up.connect(_update_style)
	pressed.connect(grab_focus)
	focus_entered.connect(_update_style)
	focus_exited.connect(_update_style)
	mouse_entered.connect(func() -> void: _hovered = true; _update_style())
	mouse_exited.connect(func() -> void: _hovered = false; _update_style())
	style_changed.connect(_update_style)
	_update_style()

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

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"icon":
			icon = value
			_glyph_icon.texture = icon
			_glyph_icon.visible = icon != null
			_glyph_text.visible = icon == null
			return true
		&"text":
			text = value
			_fancy_text.text = text
			return true
	return false
