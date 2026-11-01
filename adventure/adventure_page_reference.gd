@tool
@abstract
class_name AdventurePageReference
extends Resource

@abstract func prepare() -> void
@abstract func get_adventure_page() -> AdventurePage

## The page, loaded at once (not threaded) when it is in another file; none for references only the story resolves
func load_page() -> AdventurePage: return get_adventure_page()

## Whether the player has been on the page this leads to; true for references only the story resolves (they lead back)
func was_visited(story: Story) -> bool:
	var page: AdventurePage = get_adventure_page()
	return page == null or story.get_how_often_page_has_been_entered(page) > 0

## The page this leads to in [param story]; most references know it without the story
func resolve(_story: Story) -> AdventurePage: return get_adventure_page()
