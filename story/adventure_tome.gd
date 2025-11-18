class_name AdventureTome
extends Resource

@export var title: String
@export var starting_page: StoryPage
@export var protagonist: CharacterProfile

func start_adventure() -> void:
	var adventure: Adventure = await Main.load_new_adventure()
	adventure.adventure_tome = self
