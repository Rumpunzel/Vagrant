class_name AdventureKillMonsterConsequence
extends AdventureConsequence

## Needs [member AdventureMonsterReference.spawned_by]: consequences don't know their page
@export var monster: AdventureMonsterReference

func resolve(story: Story, _margin: int) -> void:
	monster.get_monster(story).dead = true
