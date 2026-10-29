@tool
class_name AdventureMonsterCondition
extends AdventureCondition

## True while a spawned monster is in [member state]

enum State {
	## Up to a fight
	CAN_FIGHT,
	## Beaten but alive
	INCAPACITATED,
	DEAD,
}

const STATE_TEXTS: Dictionary[State, String] = {State.CAN_FIGHT: "can fight", State.INCAPACITATED: "is beaten", State.DEAD: "is dead"}

@export var monster: AdventureMonsterReference
@export var state: State

func is_true(story: Story, page: AdventurePage) -> bool:
	var target: Monster = monster.get_monster(story, page)
	match state:
		State.CAN_FIGHT: return target.can_fight()
		State.INCAPACITATED: return target.incapacitated and not target.dead
	return target.dead

func describe() -> String:
	var monster_name: String = monster.monster.name if monster != null and monster.monster != null else "Monster"
	return "%s %s" % [monster_name, STATE_TEXTS[state]]
