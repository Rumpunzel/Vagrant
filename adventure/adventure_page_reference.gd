@tool
@abstract
class_name AdventurePageReference
extends Resource

@abstract func prepare() -> void
@abstract func get_adventure_page() -> AdventurePage

## The page, loaded at once (not threaded) when it is in another file; none for references only the story resolves
func load_page() -> AdventurePage: return get_adventure_page()

## The page this leads to in [param story]; most references know it without the story
func resolve(_story: Story) -> AdventurePage: return get_adventure_page()
