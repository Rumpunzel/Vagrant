extends Node

signal save_requested(save_request: HitDiceSelection.SaveRequest)
signal save_evaluated(save_result: SaveResult, save_request: HitDiceSelection.SaveRequest)

signal location_changed(background: Texture)
