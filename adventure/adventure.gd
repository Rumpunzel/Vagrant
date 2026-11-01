class_name Adventure
extends Resource

@export var title: String
@export var starting_page: AdventurePage
@export var protagonist: CharacterProfile
## Who and what is in the world besides the locations' own events
@export var encounters: Array[AdventureEncounter]

## [param page]: start there instead of the starting page, its event shown on [param host] ([AdventurePlayFrom])
## [param forced]: an event played from in the adventure editor, shown on the first arrival whatever its conditions
func start_adventure(page: AdventurePage = null, host: AdventurePage = null, forced: AdventureEvent = null) -> void: Main.enter_story(self, page, host, forced)
