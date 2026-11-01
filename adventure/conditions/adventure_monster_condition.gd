@tool
class_name AdventureMonsterCondition
extends AdventureCondition

## True while an encounter's monster is in [member state]: its body as the fights left it (stages are for its story)

enum State {
	## Up to a fight
	CAN_FIGHT,
	## Beaten (incapacitated) but alive
	BEATEN,
	DEAD,
}

const STATE_TEXTS: Dictionary[State, String] = {State.CAN_FIGHT: "can fight", State.BEATEN: "is beaten", State.DEAD: "is dead"}

## By UID; empty: the event's own encounter
@export_file("*.tres") var encounter: String
@export var state: State

func is_true(story: Story, page: AdventurePage) -> bool:
	var target: AdventureEncounter = story.get_subject(encounter, page) as AdventureEncounter
	if target == null or not target.profile is MonsterProfile: return false
	var monster: Monster = story.get_monster(target, target.profile as MonsterProfile)
	match state:
		State.CAN_FIGHT: return monster.can_fight()
		State.BEATEN: return monster.incapacitated and not monster.dead
	return monster.dead

func describe() -> String:
	var who: String = "It" if encounter.is_empty() else AdventureStageCondition.name_subject(encounter)
	return "%s %s" % [who, STATE_TEXTS[state]]
