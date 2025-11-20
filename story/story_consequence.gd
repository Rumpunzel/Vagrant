class_name StoryConsequence
extends RefCounted

var _adventure_consequence: AdventureConsequence

func _init(adventure_consequence: AdventureConsequence) -> void:
	_adventure_consequence = adventure_consequence

func resolve() -> void: pass
