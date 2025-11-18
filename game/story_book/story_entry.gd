@tool
class_name StoryEntry
extends PageEntry

@export_range(0.0, 1.0) var _options_fade_in_duration: float = 0.25
@export_range(0.0, 1.0) var _options_fade_in_delay: float = 0.1

@export_group("Configuration")
@export var _title: TypingLabel
@export var _description: TypingLabel
@export var _choices: FlexContainer
@export var _breath_dice_collapsible_container: CollapsibleContainer
@export var _breath_dice_selection: BreathDiceSelection
@export var _dialog_button: PackedScene

var story_book_page: StoryBookPage : set = set_story_book_page

var _save_request: SaveRequest:
	set(new_save_request):
		_save_request = new_save_request
		if not _save_request:
			if not _fight_request: _breath_dice_collapsible_container.close_tween()
			return
		_breath_dice_selection.request_save(_save_request)
		await get_tree().process_frame
		_breath_dice_collapsible_container.open_tween()

var _fight_request: FightRequest:
	set(new_fight_request):
		_fight_request = new_fight_request
		if not _fight_request:
			if not _save_request: _breath_dice_collapsible_container.close_tween()
			return
		_breath_dice_selection.request_fight(_fight_request)
		await get_tree().process_frame
		_breath_dice_collapsible_container.open_tween()

func enter_page() -> void:
	var title: String = story_book_page.page_title
	if not title.is_empty(): _title.type_text(title)
	else: _title.visible = false
	_description.type_text(story_book_page.description)

func is_dice_page() -> bool:
	var chosen_choice: StoryBookChoice = story_book_page.get_chosen_choice()
	return chosen_choice and chosen_choice.is_dice_choice()

func get_story_book_page() -> StoryBookPage:
	return story_book_page

func set_story_book_page(new_story_book_page: StoryBookPage) -> void:
	assert(new_story_book_page)
	story_book_page = new_story_book_page
	_update_choices(story_book_page.choices)

func _update_choices(story_book_choices: Array[StoryBookChoice]) -> void:
	_choices.clear()
	for story_book_choice: StoryBookChoice in story_book_choices: _add_dialog_button(story_book_choice)

func _add_dialog_button(story_book_choice: StoryBookChoice) -> void:
	var dialog_button: DialogButton = _dialog_button.instantiate()
	dialog_button.story_book_choice = story_book_choice
	dialog_button.modulate.a = 0.0
	dialog_button.hide()
	_choices.add(dialog_button)
	story_book_choice.chosen.connect(_on_choice_made)
	if story_book_choice is StoryBookDiceDecision: (story_book_choice as StoryBookDiceDecision).dice_requested.connect(_on_dice_requested)

func _fade_in(element: Control, duration: float, delay: float = 0.0) -> void:
	if element.visible: return
	var tween: Tween = create_tween()
	tween.tween_property(element, "modulate:a", 1.0, duration).set_delay(delay)
	element.show()

func _fade_out(element: Control, duration: float, delay: float = 0.0) -> void:
	if not element.visible: return
	var tween: Tween = create_tween()
	tween.tween_property(element, "modulate:a", 0.0, duration).set_delay(delay)
	await tween.finished
	element.hide()

func _set_state(new_state: State) -> void:
	super._set_state(new_state)
	for dialog_button: DialogButton in _choices.get_elements(): dialog_button.state = state

func _on_description_finished_typing() -> void:
	var buttons: Array[DialogButton] = []
	buttons.assign(_choices.get_elements())
	for index: int in buttons.size():
		var button: DialogButton = buttons[index]
		_fade_in(button, _options_fade_in_duration, _options_fade_in_delay * index)

func _on_choice_made() -> void:
	state = State.PAST

func _on_dice_requested(dice_request: DiceRequest) -> void:
	assert(dice_request)
	if dice_request is SaveRequest: _on_save_requested(dice_request as SaveRequest)
	elif dice_request is FightRequest: _on_fight_requested(dice_request as FightRequest)
	else: assert(false, "Undefined")

func _on_save_requested(save_request: SaveRequest) -> void:
	assert(save_request)
	_save_request = save_request
	_fight_request = null

func _on_fight_requested(fight_request: FightRequest) -> void:
	assert(fight_request)
	_fight_request = fight_request
	_save_request = null

func _on_breath_dice_selection_confirmed() -> void:
	if _save_request:
		assert(not _fight_request)
		_save_request.roll_save()
	elif _fight_request:
		assert(not _save_request)
		_fight_request.roll_fight()
	else: assert(false)
	_breath_dice_collapsible_container.auto_update_size = CollapsibleContainer.AutoUpdateSizeOptions.DISABLED
