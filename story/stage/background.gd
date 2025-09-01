@tool
class_name BackgroundRect
extends TextureRect

func _ready() -> void:
	material = material.duplicate()

func fade_in(duration: float = 1.0) -> void:
	var tween: Tween = get_tree().create_tween().set_parallel()
	assert(material is ShaderMaterial)
	var shader_material: ShaderMaterial = material
	tween.tween_property(material, "shader_parameter/up", shader_material.get_shader_parameter("up"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/down", shader_material.get_shader_parameter("down"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/left", shader_material.get_shader_parameter("left"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/right", shader_material.get_shader_parameter("right"), duration).from(1.0)

func fade_out(duration: float = 2.0, delete_after: bool = true) -> void:
	var tween: Tween = get_tree().create_tween().set_parallel()
	tween.tween_property(material, "shader_parameter/up", 1.0, duration)
	tween.tween_property(material, "shader_parameter/down", 1.0, duration)
	tween.tween_property(material, "shader_parameter/left", 1.0, duration)
	tween.tween_property(material, "shader_parameter/right", 1.0, duration)
	if delete_after:
		await tween.finished
		queue_free()
