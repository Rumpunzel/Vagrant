@tool
extends Node

const d4: DieType = preload("uid://damgavu0n4rho")
const d6: DieType = preload("uid://clrjpyohkfypv")
const d8: DieType = preload("uid://c3ciobci54n6u")
const d10: DieType = preload("uid://dtfdogfd6ebga")
const d12: DieType = preload("uid://cq2oc01qwwaei")

const BREATH_DICE: Dictionary[DieType, int] = {
	d4: 1,
	d6: 1,
	d8: 1,
	d10: 1,
	d12: 1,
}

const STRENGTH: CharacterAttribute = preload("uid://b1c6aib060ja5")
const AGILITY: CharacterAttribute = preload("uid://bu20awm3swywv")
const INTELLIGENCE: CharacterAttribute = preload("uid://2vf8mdpla1u2")

const ATTRIBUTES: Array[CharacterAttribute] = [ STRENGTH, AGILITY, INTELLIGENCE ]

func _init() -> void:
	BREATH_DICE.make_read_only()
	ATTRIBUTES.make_read_only()
