@tool
class_name BackgroundRect
extends TextureRect

signal faded_in
signal faded_out

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not material: return
	material = material.duplicate()
	fade_in()

func fade_in(duration: float = 1.0) -> void:
	var tween: Tween = get_tree().create_tween().set_parallel()
	assert(material is ShaderMaterial)
	var shader_material: ShaderMaterial = material
	tween.tween_property(material, "shader_parameter/up", shader_material.get_shader_parameter("up"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/down", shader_material.get_shader_parameter("down"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/left", shader_material.get_shader_parameter("left"), duration).from(1.0)
	tween.tween_property(material, "shader_parameter/right", shader_material.get_shader_parameter("right"), duration).from(1.0)
	await tween.finished
	faded_in.emit()

func fade_out(duration: float = 2.0, delete_after: bool = true) -> void:
	var tween: Tween = get_tree().create_tween().set_parallel()
	tween.tween_property(material, "shader_parameter/power", 4.0, duration)
	tween.tween_property(material, "shader_parameter/up", 1.0, duration)
	tween.tween_property(material, "shader_parameter/down", 1.0, duration)
	tween.tween_property(material, "shader_parameter/left", 1.0, duration)
	tween.tween_property(material, "shader_parameter/right", 1.0, duration)
	await tween.finished
	faded_out.emit()
	if delete_after: queue_free()
