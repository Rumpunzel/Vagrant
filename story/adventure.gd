class_name Adventure
extends Resource

@export var title: String
@export var starting_page: StoryPage
@export var protagonist: CharacterProfile

func start_adventure() -> void:
	Main.enter_story(self)
