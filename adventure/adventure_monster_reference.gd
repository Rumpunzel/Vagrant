class_name AdventureMonsterReference
extends Resource

## Points at one spawned monster: a profile spawned by a page (see [method Story.get_monster])

@export var monster: MonsterProfile
## Which of the page's monsters of this profile, as in its fight decision's enemies
@export var index: int = 0
## The page whose fight spawned it; none: the page using this reference
@export var spawned_by: AdventurePageReference

func get_monster(story: Story, page: AdventurePage = null) -> Monster:
	assert(monster)
	var spawning_page: AdventurePage = spawned_by.get_adventure_page() if spawned_by else page
	assert(spawning_page, "A monster reference outside a page needs spawned_by")
	return story.get_monster(spawning_page, monster, index)
