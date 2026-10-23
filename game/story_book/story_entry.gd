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
@export var _injuries: Container
@export var _outcome: TypingLabel
@export var _injury_display: PackedScene
@export var _dialog_button: PackedScene

var story_page: StoryPage : set = set_story_page
var chosen_decision: StoryChoice

func enter_page() -> void:
	super.enter_page()
	var title: String = story_page.page_title
	if not title.is_empty(): _title.type_text(title)
	else: _title.visible = false
	_description.type_text(story_page.description)

func request_dice(dice_request: DiceRequest) -> void:
	if not dice_request:
		_breath_dice_collapsible_container.close_tween()
		return
	_breath_dice_selection.request_dice(dice_request)
	await get_tree().process_frame
	_breath_dice_collapsible_container.open_tween()

func show_injury(target_name: String, magnitude: int) -> void:
	var injury_display: InjuryDisplay = _injury_display.instantiate()
	_injuries.add_child(injury_display)
	injury_display.setup(target_name, magnitude)
	_injuries.visible = true

## Shows [param panel] above the outcome, e.g. to decide something mid-exchange without turning the page
func show_panel(panel: Control) -> void:
	_outcome.add_sibling(panel)
	_outcome.get_parent().move_child(panel, _outcome.get_index())

## Starts typing [param outcome]; see [method is_outcome_typed]
func show_outcome(outcome: String) -> void:
	if outcome.is_empty(): return
	_outcome.visible = true
	_outcome.type_text(outcome)

func is_outcome_typed() -> bool: return _outcome.visible_ratio >= 1.0
func get_outcome_typed() -> Signal: return _outcome.finished_typing

func display_dice_result(dice_result: DiceRequestResult) -> void:
	_breath_dice_selection.display_dice_result(dice_result)

func display_dice_evaluation(dice_result: DiceRequestResult) -> void:
	_breath_dice_selection.display_dice_evaluation(dice_result)

func is_dice_page() -> bool:
	var chosen_choice: StoryChoice = story_page.get_chosen_choice()
	return chosen_choice and chosen_choice.is_dice_choice()

func get_story_page() -> StoryPage:
	return story_page

func set_story_page(new_story_page: StoryPage) -> void:
	assert(new_story_page)
	story_page = new_story_page
	_update_choices(story_page.choices)

func _update_choices(story_choices: Array[StoryChoice]) -> void:
	_choices.clear()
	var dialog_button_group: ButtonGroup = ButtonGroup.new()
	for story_choice: StoryChoice in story_choices: _add_dialog_button(story_choice, dialog_button_group)

func _add_dialog_button(story_choice: StoryChoice, dialog_button_group: ButtonGroup) -> void:
	var dialog_button: DialogButton = _dialog_button.instantiate()
	dialog_button.setup(story_choice, dialog_button_group)
	dialog_button.modulate.a = 0.0
	dialog_button.hide()
	_choices.add(dialog_button)
	story_choice.chosen.connect(_on_choice_made.bind(story_choice))
	story_choice.dice_requested.connect(_on_dice_requested.bind(story_choice))

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

func _on_choice_made(story_decision: StoryChoice) -> void:
	chosen_decision = story_decision

func _on_dice_requested(dice_request: DiceRequest, story_dice_decision: StoryDiceDecision) -> void:
	chosen_decision = story_dice_decision
	request_dice(dice_request)

func _on_breath_dice_selection_confirmed() -> void:
	chosen_decision.roll()
	_breath_dice_collapsible_container.auto_update_size = CollapsibleContainer.AutoUpdateSizeOptions.DISABLED
