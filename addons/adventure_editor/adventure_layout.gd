@tool
class_name AdventureLayout
extends Resource

## Where the adventure editor places the pages of one adventure; a file next to the adventure, so moving nodes leaves game data alone

## Graph positions by page UID (path for pages without one)
@export var positions: Dictionary[String, Vector2] = {}
## Which special node (host, previous location) a link goes to, by the link's key; event views can show several of each
@export var special_links: Dictionary[String, String] = {}

static func get_path_for(adventure: Adventure) -> String:
	return adventure.resource_path.get_basename() + ".layout.tres"

static func load_for(adventure: Adventure) -> AdventureLayout:
	var path: String = get_path_for(adventure)
	var layout: AdventureLayout = load(path) if ResourceLoader.exists(path) else null
	return layout if layout != null else AdventureLayout.new()

## A file's UID (its path without one); a resource inside a file: its ID there, which it keeps when saved
static func get_key(resource: Resource) -> String:
	if resource.resource_path.is_empty() or resource.resource_path.contains("::"): return "::" + resource.resource_scene_unique_id
	var uid: int = ResourceLoader.get_resource_uid(resource.resource_path)
	return ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else resource.resource_path

## Map pages placed by hand, reachable or not; event views' keys join several keys
func get_placed_pages() -> Array[AdventurePage]:
	var placed: Array[AdventurePage] = [ ]
	for key: String in positions:
		if key.count("://") != 1 or not ResourceLoader.exists(key): continue
		var page: AdventurePage = load(key) as AdventurePage
		if page != null: placed.append(page)
	return placed

func save_for(adventure: Adventure) -> void:
	ResourceSaver.save(self, get_path_for(adventure))
