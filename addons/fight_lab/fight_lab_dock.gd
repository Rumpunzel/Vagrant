@tool
extends VBoxContainer

## The Fight Lab's bottom panel: pick a [FightLabScenario] and how to run it, run it in a headless Godot process, show the result.
## The run settings are kept in [constant SETTINGS_FILE] for the child process and for next time. A scenario saved in no file (as the adventure
## editor's, [method open_scenario]) is kept inside them.

const FightLabResults: GDScript = preload("uid://cuh3q2c6v1lmb")  # fight_lab_results.gd
const FightLabFightView: GDScript = preload("uid://cnyxw8v3kh2qa")  # fight_lab_fight_view.gd
const SETTINGS_FILE: String = "user://fight_lab/settings.tres"
const RESULT_FILE: String = "user://fight_lab/result.json"

var _settings: FightLabRunSettings
var _scenario_picker: EditorResourcePicker
var _mode: OptionButton
var _fights: EditorSpinSlider
var _sweep_picker: EditorResourcePicker
var _a_option: OptionButton
var _b_option: OptionButton
var _max_exchanges: EditorSpinSlider
var _seed: SpinBox
var _run_button: Button
var _progress: ProgressBar
var _status: Label
var _section_bar: HBoxContainer
var _results: Control
var _fight_view: Control
var _runner: FightLabProcess
## Shared by the results and the one-fight view
var _tooltips: FightLabTooltips = FightLabTooltips.new()

func _init() -> void:
	name = "Fight Lab"
	custom_minimum_size = Vector2(0, 300)
	_settings = _load_settings()
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_scenario_picker = _picker("FightLabScenario", bar)
	_scenario_picker.edited_resource = _settings.scenario
	_scenario_picker.resource_changed.connect(func(_resource: Resource) -> void: _update_pairing_options())
	_mode = OptionButton.new()
	_mode.add_item("Many fights", FightLabRunSettings.Mode.MANY_FIGHTS)
	_mode.add_item("One fight", FightLabRunSettings.Mode.ONE_FIGHT)
	_mode.selected = _settings.mode
	_mode.item_selected.connect(func(_index: int) -> void: _update_mode())
	bar.add_child(_mode)
	_fights = _spin_slider("Fights", 1, 10000, _settings.fights, bar)
	_sweep_picker = _picker("FightLabSweep", bar)
	_sweep_picker.edited_resource = _settings.sweep
	_a_option = OptionButton.new()
	bar.add_child(_a_option)
	_b_option = OptionButton.new()
	bar.add_child(_b_option)
	_max_exchanges = _spin_slider("Max exchanges", 1, 200, _settings.max_exchanges, bar)
	_seed = SpinBox.new()
	_seed.prefix = "Seed"
	_seed.max_value = 999999
	_seed.value = _settings.random_seed
	bar.add_child(_seed)
	_run_button = Button.new()
	_run_button.text = "Run"
	_run_button.pressed.connect(_run)
	bar.add_child(_run_button)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.x = 120
	_progress.visible = false
	bar.add_child(_progress)
	_status = Label.new()
	_status.clip_text = true
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_status)
	_section_bar = HBoxContainer.new()
	add_child(_section_bar)
	var shown: Array = _settings.sections if not _settings.sections.is_empty() else FightLabResults.SECTIONS.keys()
	for key: String in FightLabResults.SECTIONS:
		var check: CheckBox = CheckBox.new()
		check.text = FightLabResults.SECTIONS[key]
		check.button_pressed = shown.has(key)
		check.toggled.connect(func(_on: bool) -> void: _update_sections())
		check.set_meta("section", key)
		_explain(check, "[b]%s[/b]\n%s" % [FightLabResults.SECTIONS[key], FightLabTooltips.SECTIONS[key]])
		_section_bar.add_child(check)
	_results = FightLabResults.new()
	_results.set(&"tooltips", _tooltips)
	add_child(_results)
	_fight_view = FightLabFightView.new()
	_fight_view.set(&"tooltips", _tooltips)
	_fight_view.visible = false
	add_child(_fight_view)
	var explained: Dictionary[Control, String] = {
		_scenario_picker: "scenario", _mode: "mode", _fights: "fights", _sweep_picker: "sweep",
		_max_exchanges: "max_exchanges", _seed: "seed", _a_option: "pairing", _b_option: "pairing",
	}
	for control: Control in explained: _explain(control, FightLabTooltips.CONTROLS[explained[control]])
	_update_pairing_options()
	_update_mode()
	_update_sections()
	_runner = FightLabProcess.new()
	_runner.progressed.connect(_on_progressed)
	_runner.finished.connect(_on_finished)
	add_child(_runner)

func _ready() -> void:
	if FileAccess.file_exists(RESULT_FILE): _load_result("Last result")

## Runs [param scenario] (many fights) as the adventure editor asks; one saved in no file is kept in the settings
func open_scenario(scenario: FightLabScenario) -> void:
	_scenario_picker.edited_resource = scenario
	_mode.select(_mode.get_item_index(FightLabRunSettings.Mode.MANY_FIGHTS))
	_sweep_picker.edited_resource = null
	_update_pairing_options()
	_update_mode()
	_run()

func _run() -> void:
	var scenario: FightLabScenario = _scenario_picker.edited_resource as FightLabScenario
	if not scenario or scenario.resource_path.contains("::"):
		_status.text = "Pick a scenario saved as its own .tres file."
		return
	# The child process reads both from disk
	if scenario.resource_path.begins_with("res://"): ResourceSaver.save(scenario)
	_store_settings()
	if not _runner.start(_settings, SETTINGS_FILE, RESULT_FILE):
		_status.text = "Could not start Godot."
		return
	_run_button.disabled = true
	_progress.visible = true
	_progress.value = 0
	_status.text = "Simulating…"

func _on_progressed(done: int, total: int) -> void:
	if total > 0: _progress.value = 100.0 * done / total

func _on_finished(_result: Dictionary) -> void:
	_run_button.disabled = false
	_progress.visible = false
	_load_result("Done")

func _load_result(status: String) -> void:
	var result: Dictionary = FightLabProcess.read_result(RESULT_FILE)
	if result.is_empty():
		_status.text = "The simulation failed; run the runner scene by hand to see why." if status == "Done" else ""
		return
	_tooltips.scenario = _scenario_picker.edited_resource as FightLabScenario
	var one_fight: bool = result.has("fight")
	_results.visible = not one_fight
	_section_bar.visible = not one_fight
	_fight_view.visible = one_fight
	if one_fight:
		_fight_view.show_result(result)
		_status.text = "%s: one fight." % status
		return
	_results.show_result(result)
	var cells: Array = result["cells"]
	_status.text = "%s: %d cells × %d fights." % [status, cells.size(), cells[0]["stats"]["runs"] if not cells.is_empty() else 0]
	var skipped: Array = result.get("skipped", [])
	if not skipped.is_empty(): _status.text += " Skipped (attributes not rolled): %s." % ", ".join(skipped)

func _update_mode() -> void:
	var one_fight: bool = _mode.get_selected_id() == FightLabRunSettings.Mode.ONE_FIGHT
	_fights.visible = not one_fight
	_sweep_picker.visible = not one_fight
	_a_option.visible = one_fight
	_b_option.visible = one_fight
	_run_button.text = "Fight" if one_fight else "Run"

## The scenario's sides to pick the one fight from
func _update_pairing_options() -> void:
	var scenario: FightLabScenario = _scenario_picker.edited_resource as FightLabScenario
	for option: OptionButton in [_a_option, _b_option]: option.clear()
	if not scenario: return
	for row: int in scenario.get_row_count(): _a_option.add_item(scenario.get_row_name(row))
	for profile: ActorProfile in scenario.side_b: _b_option.add_item(profile.name if profile else "(empty)")
	_a_option.selected = clampi(_settings.a, 0, _a_option.item_count - 1)
	_b_option.selected = clampi(_settings.b, 0, _b_option.item_count - 1)

func _update_sections() -> void:
	_settings.sections = _get_sections()
	_results.set_sections(_get_sections())

func _get_sections() -> Array[String]:
	var sections: Array[String] = []
	for check: Node in _section_bar.get_children():
		if (check as CheckBox).button_pressed: sections.append(check.get_meta("section"))
	return sections

func _store_settings() -> void:
	_settings.scenario = _scenario_picker.edited_resource as FightLabScenario
	_settings.mode = _mode.get_selected_id() as FightLabRunSettings.Mode
	_settings.fights = int(_fights.value)
	_settings.max_exchanges = int(_max_exchanges.value)
	_settings.random_seed = int(_seed.value)
	_settings.sweep = _sweep_picker.edited_resource as FightLabSweep
	_settings.a = maxi(_a_option.selected, 0)
	_settings.b = maxi(_b_option.selected, 0)
	_settings.sections = _get_sections()

static func _load_settings() -> FightLabRunSettings:
	var settings: FightLabRunSettings = null
	if FileAccess.file_exists(SETTINGS_FILE): settings = ResourceLoader.load(SETTINGS_FILE, "", ResourceLoader.CACHE_MODE_IGNORE) as FightLabRunSettings
	return settings if settings else FightLabRunSettings.new()

## A rich tooltip with a fixed [param text]
func _explain(control: Control, text: String) -> void:
	_tooltips.attach(control, func() -> String: return text)

static func _picker(base_type: String, parent: Control) -> EditorResourcePicker:
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = base_type
	picker.custom_minimum_size.x = 200
	parent.add_child(picker)
	return picker

static func _spin_slider(label: String, min_value: int, max_value: int, value: int, parent: Control) -> EditorSpinSlider:
	var slider: EditorSpinSlider = EditorSpinSlider.new()
	slider.label = label
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size.x = 150
	parent.add_child(slider)
	return slider
