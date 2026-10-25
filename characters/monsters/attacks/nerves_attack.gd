class_name NervesAttack
extends MonsterAttack

@export var target: CharacterAttribute

func get_stance() -> CharacterAttribute: return Rules.INTELLIGENCE
func get_nerves_target() -> CharacterAttribute: return target
