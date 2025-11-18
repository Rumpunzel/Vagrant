class_name Game
extends Node

signal party_changed(party: Characters)
signal npcs_changed(npcs: Characters)

@export var _party: Characters :
	set(new_party):
		assert(new_party)
		_party = new_party
		party_changed.emit(_party)
@export var _npcs: Characters :
	set(new_npcs):
		assert(new_npcs)
		_npcs = new_npcs
		npcs_changed.emit(_npcs)

func setup(party: Characters, npcs: Characters) -> void:
	_party = party
	_npcs = npcs
