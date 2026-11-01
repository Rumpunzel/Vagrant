@tool
class_name AdventureKillConsequence
extends AdventureConsequence

## Kills an encounter's monster

## By UID; empty: the encounter of the event one is in
@export_file("*.tres") var encounter: String

func resolve(story: Story, _margin: int) -> void:
	var target: AdventureEncounter = story.get_subject(encounter, null) as AdventureEncounter
	if target == null or not target.profile is MonsterProfile: return
	story.get_monster(target, target.profile as MonsterProfile).dead = true

func describe() -> String:
	return "Kill %s" % ("it" if encounter.is_empty() else AdventureStageCondition.name_subject(encounter))
