@tool
class_name AdventureLayout
extends Resource

## Where the adventure editor places the pages of one adventure; a file next to the adventure, so moving nodes leaves game data alone

## Graph positions by page UID (path for pages without one)
@export var positions: Dictionary[String, Vector2] = {}

static func get_path_for(adventure: Adventure) -> String:
	return adventure.resource_path.get_basename() + ".layout.tres"

static func load_for(adventure: Adventure) -> AdventureLayout:
	var path: String = get_path_for(adventure)
	var layout: AdventureLayout = load(path) if ResourceLoader.exists(path) else null
	return layout if layout != null else AdventureLayout.new()

static func get_key(resource: Resource) -> String:
	var uid: int = ResourceLoader.get_resource_uid(resource.resource_path)
	return ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else resource.resource_path

func save_for(adventure: Adventure) -> void:
	ResourceSaver.save(self, get_path_for(adventure))
