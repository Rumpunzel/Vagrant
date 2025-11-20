class_name StoryConsequence
extends RefCounted

var _adventure_consequence: AdventureConsequence

func _init(adventure_consequence: AdventureConsequence) -> void:
	_adventure_consequence = adventure_consequence

static func from_adventure_consequence(adventure_consequence: AdventureConsequence) -> StoryConsequence:
	return new(adventure_consequence)

func resolve(protagonist: Character, damage: int) -> void:
	assert(protagonist)
	_adventure_consequence.resolve(protagonist, damage)
