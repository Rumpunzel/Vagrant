@tool
extends Node

const d4: DieType = preload("uid://damgavu0n4rho")
const d6: DieType = preload("uid://clrjpyohkfypv")
const d8: DieType = preload("uid://c3ciobci54n6u")
const d10: DieType = preload("uid://dtfdogfd6ebga")
const d12: DieType = preload("uid://cq2oc01qwwaei")

const STRENGTH: CharacterAttribute = preload("uid://b1c6aib060ja5")
const AGILITY: CharacterAttribute = preload("uid://bu20awm3swywv")
const INTELLIGENCE: CharacterAttribute = preload("uid://2vf8mdpla1u2")

const ATTRIBUTES: Array[CharacterAttribute] = [
	STRENGTH,
	AGILITY,
	INTELLIGENCE,
]

const ADVENTURER: Origin = preload("uid://ciavtykggnu43")
const NOBLE: Origin = preload("uid://bax71w1etiyel")
const OUTLAW: Origin = preload("uid://binkm27w771kw")
const PEASANT: Origin = preload("uid://c7j5c7ekitgl3")
const SAILOR: Origin = preload("uid://cy17lbnstbpf2")
const SCHOLAR: Origin = preload("uid://bpesh0vj6mbdm")
const SOLDIER: Origin = preload("uid://cawcb1f8r3nb8")
const THIEF: Origin = preload("uid://bj6k6l430dyvn")
const VETERAN: Origin = preload("uid://45sbhcfyenlm")

const ORIGINS: Array[Origin] = [
	ADVENTURER,
	NOBLE,
	OUTLAW,
	PEASANT,
	SAILOR,
	SCHOLAR,
	SOLDIER,
	THIEF,
	VETERAN,
]
