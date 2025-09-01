class_name Candle
extends Sprite2D

@export var _candle_noise: Noise
@export var _color_flicker_speed: float = 64.0
@export_range(0.0, 1.0) var _color_flicker_magnitude: float = 0.1
@export var _offset_flicker_speed: float = 32.0
@export_range(0.0, 1.0) var _offset_flicker_magnitude: float = 0.1

var _time_passed: float = 0.0

@onready var _light_texture: GradientTexture2D = texture
@onready var _gradient: Gradient = _light_texture.gradient
@onready var _colors: Array = Array(_gradient.colors.duplicate())
@onready var _color_offsets: Array = Array(_gradient.offsets.duplicate())

func _process(delta: float) -> void:
	_time_passed += delta
	var color_noise_sample: float = _candle_noise.get_noise_1d(_time_passed * _color_flicker_speed) * _color_flicker_magnitude
	_gradient.colors = _colors.map(func(color: Color) -> Color: return Color(color, color.a + color_noise_sample))
	var offset_noise_sample: float = _candle_noise.get_noise_1d(_time_passed * _offset_flicker_speed) * _offset_flicker_magnitude
	_gradient.offsets = _color_offsets.map(func(color_offset: float) -> float: return color_offset + offset_noise_sample)
