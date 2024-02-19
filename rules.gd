extends Node

const d4: DieType = preload("res://dice/die_types/d4.tres")
const d6: DieType = preload("res://dice/die_types/d6.tres")
const d8: DieType = preload("res://dice/die_types/d8.tres")
const d10: DieType = preload("res://dice/die_types/d10.tres")
const d12: DieType = preload("res://dice/die_types/d12.tres")

const STRENGTH: CharacterAttribute = preload("res://characters/attributes/strength.tres")
const AGILITY: CharacterAttribute = preload("res://characters/attributes/agility.tres")
const CONSTITUTION: CharacterAttribute = preload("res://characters/attributes/constitution.tres")
const INTELLIGENCE: CharacterAttribute = preload("res://characters/attributes/intelligence.tres")
const WILL: CharacterAttribute = preload("res://characters/attributes/will.tres")
const CHARISMA: CharacterAttribute = preload("res://characters/attributes/charisma.tres")

const ATTRIBUTES: Array[CharacterAttribute] = [
	STRENGTH,
	AGILITY,
	CONSTITUTION,
	INTELLIGENCE,
	WILL,
	CHARISMA,
]
