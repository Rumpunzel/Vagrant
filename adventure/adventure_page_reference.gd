@tool
@abstract
class_name AdventurePageReference
extends Resource

@abstract func prepare() -> void
@abstract func get_adventure_page() -> AdventurePage

## The page this leads to in [param story]; most references know it without the story
func resolve(_story: Story) -> AdventurePage: return get_adventure_page()
