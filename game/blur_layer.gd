extends CanvasLayer

@export_range(0.0, 1.0) var _fade_in_duration: float = 1.0
@export_range(0.0, 3.0) var _fade_out_duration: float = 0.25
@export_range(0.0, 1.0) var _fade_out_delay: float = 0.0

@export_group("Configuration")
@export var _blur: ColorRect

@onready var _blur_material: ShaderMaterial = _blur.material.duplicate()

func _ready() -> void:
	visible = false
	_blur.material = _blur_material
	_blur_material.set_shader_parameter("lod", 0.0)
	_blur_material.set_shader_parameter("mix_percentage", 0.0)

func fade_in(fade_in_duration: float = _fade_in_duration) -> void:
	visible = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_blur_material, "shader_parameter/lod", 0.5, fade_in_duration)
	tween.tween_property(_blur_material, "shader_parameter/mix_percentage", 0.3, fade_in_duration)

func fade_out(fade_out_duration: float = _fade_out_duration, fade_out_delay: float = _fade_out_delay) -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_blur_material, "shader_parameter/lod", 0.0, fade_out_duration).set_delay(fade_out_delay)
	tween.tween_property(_blur_material, "shader_parameter/mix_percentage", 0.0, fade_out_duration).set_delay(fade_out_delay)
	await tween.finished
	visible = false
