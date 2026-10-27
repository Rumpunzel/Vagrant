@tool
class_name AdventureMapEditing
extends RefCounted

## Map edits as data, apart from undo and saving in [AdventureEditor], so they can be tested

## A plain decision leading to [param to]
static func make_link(to: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = "Go to %s." % AdventureGraph.get_title(to)
	decision.transition = AdventureTransition.leading_to(to)
	return decision

## [param page]'s decisions without the plain ones leading to [param to]; fights and saves stay
static func without_links(page: AdventurePage, to: AdventurePage) -> Array[AdventureDecision]:
	var kept: Array[AdventureDecision] = [ ]
	for decision: AdventureDecision in page.decisions:
		var leads_there: bool = decision != null and decision.transition != null and decision.transition.get_adventure_page() == to
		if not leads_there or decision is AdventureDiceDecision: kept.append(decision)
	return kept

static func make_location(title: String, area: AdventureArea) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.area = area
	return page

static func make_area(area_name: String) -> AdventureArea:
	var area: AdventureArea = AdventureArea.new()
	area.name = area_name
	return area

## Next to the area's file
static func get_location_path(area: AdventureArea, title: String) -> String:
	return area.resource_path.get_base_dir().path_join(get_file_name(title))

## In its own folder under [code]locations[/code] next to the adventure
static func get_area_path(adventure: Adventure, area_name: String) -> String:
	return adventure.resource_path.get_base_dir().path_join("locations").path_join(get_file_name(area_name).get_basename()).path_join(get_file_name(area_name))

## Snake case; every run of other characters than letters and digits becomes one "_"
static func get_file_name(title: String) -> String:
	var words: String = RegEx.create_from_string("[^\\p{L}\\p{N}]+").sub(title.to_snake_case(), "_", true).trim_prefix("_").trim_suffix("_")
	return (words if not words.is_empty() else "untitled") + ".tres"
