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

@export var monster: AdventureMonsterReference
@export var state: State

func is_true(story: Story, page: AdventurePage) -> bool:
	var target: Monster = monster.get_monster(story, page)
	match state:
		State.CAN_FIGHT: return target.can_fight()
		State.INCAPACITATED: return target.incapacitated and not target.dead
	return target.dead
