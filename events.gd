extends Node

signal save_requested(save_request: SaveRequest)
signal save_evaluated(save_result: SaveResult, save_request: SaveRequest)

signal location_changed(location: StoryLocation)
