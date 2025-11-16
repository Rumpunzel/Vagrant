@tool
class_name Glow
extends Candle

func _ready() -> void:
	resized.connect(_center_pivot_offset)

func _center_pivot_offset() -> void:
	pivot_offset = size * 0.5
