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

const ORIGINS: Array[Origin] = [
	preload("uid://ciavtykggnu43"), # adventurer
	preload("uid://7uemslxbeu5b"), # artisan
	preload("uid://dqjtp62n331s7"), # cook
	preload("uid://dgikjtge36uha"), # doctor
	preload("uid://cawcb1f8r3nb8"), # grunt
	preload("uid://cskgqp6fm3x52"), # hunter
	preload("uid://d21lprrjx41il"), # leader
	preload("uid://1n7f7ltq8e42"), # merchant
	preload("uid://de62kh1q4mybj"), # minstrel
	preload("uid://bax71w1etiyel"), # noble
	preload("uid://binkm27w771kw"), # outlaw
	preload("uid://c7j5c7ekitgl3"), # peasant
	preload("uid://cvyqjfqbkfvap"), # priest
	preload("uid://cy17lbnstbpf2"), # sailor
	preload("uid://bpesh0vj6mbdm"), # scholar
	preload("uid://yct1dsuv2io1"), # sorcerer
	preload("uid://bj6k6l430dyvn"), # thief
	preload("uid://45sbhcfyenlm"), # veteran
]
