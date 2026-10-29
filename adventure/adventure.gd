class_name Adventure
extends Resource

@export var title: String
@export var starting_page: AdventurePage
@export var protagonist: CharacterProfile

## [param page]: start there instead of the starting page, its event shown on [param host] ([AdventurePlayFrom])
func start_adventure(page: AdventurePage = null, host: AdventurePage = null) -> void: Main.enter_story(self, page, host)
