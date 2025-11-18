@tool
extends Node

var d4: DieType = load("uid://damgavu0n4rho")
var d6: DieType = load("uid://clrjpyohkfypv")
var d8: DieType = load("uid://c3ciobci54n6u")
var d10: DieType = load("uid://dtfdogfd6ebga")
var d12: DieType = load("uid://cq2oc01qwwaei")

var BREATH_DICE: Array[DieType] = [ d4, d6, d8, d10, d12 ]

var STRENGTH: CharacterAttribute = load("uid://b1c6aib060ja5")
var AGILITY: CharacterAttribute = load("uid://bu20awm3swywv")
var INTELLIGENCE: CharacterAttribute = load("uid://2vf8mdpla1u2")

var ATTRIBUTES: Array[CharacterAttribute] = [ STRENGTH, AGILITY, INTELLIGENCE ]
