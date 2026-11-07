@tool
class_name AdventureLootDecision
extends AdventureDecision

## Searching an encounter's monster ("Search the Lurker."): a page lists what is there to take, its usable gear (marks and all) and its
## [member AdventureEncounter.loot], one choice each; "Leave the rest." (or taking the last of it) follows [member transition].
## Not offered once nothing is left.

## By UID; empty: the encounter of the event it is in
@export_file("*.tres") var encounter: String

## The encounter searched: the named one, else [param own]
func get_looted(own: AdventureEncounter) -> AdventureEncounter:
	return Files.load_existing(encounter) as AdventureEncounter if not encounter.is_empty() else own
