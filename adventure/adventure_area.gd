class_name AdventureArea
extends Resource

@export_placeholder("Name") var name: String
@export var background: Texture
@export var ambience: AudioStream
## Shown on arriving at one of its locations from another area (or at the start), before the location's text
@export_multiline var description: String
## Shown instead the first time
@export_multiline var first_description: String
