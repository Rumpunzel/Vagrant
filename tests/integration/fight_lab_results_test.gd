extends GdUnitTestSuite

## Fight Lab results view: every view and section builds and draws its charts (box plots, outcome splits) without errors.

var _results: Control

func before_test() -> void:
	_results = auto_free(load("uid://cuh3q2c6v1lmb").new())  # fight_lab_results.gd
	_results.size = Vector2(1400, 600)
	add_child(_results)

func test_every_view_draws() -> void:
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [TestCharacters.adventurer(), TestCharacters.adventurer()] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	var settings: FightLabRunSettings = FightLabRunSettings.new()
	settings.scenario = scenario
	settings.fights = 20
	var result: Dictionary = FightLabRun.new(settings).execute(self)
	_results.set_sections(["outcome", "cost", "damage", "length", "gear"] as Array[String])
	_results.show_result(JSON.parse_string(JSON.stringify(result)))
	await _draw_frames()
	# Row, column, one cell (its distributions) and two cells side by side
	_results._select_column(0)
	await _draw_frames()
	_results._on_cell_pressed(Vector2i(0, 0))
	await _draw_frames()
	assert_int(_charts().size()).is_greater(5)
	_results._selection = [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i]
	_results._refresh()
	await _draw_frames()
	assert_bool(_charts().any(func(chart: Control) -> bool: return chart.boxed)).is_true()
	# Hovering a chart's first category tells all its series and the fights behind them
	var chart: Control = _charts()[0]
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = Vector2(chart.MARGIN.x + 2.0, chart.size.y / 2.0)
	chart._gui_input(event)
	assert_str(chart.describe_hovered()).contains("[b]%s[/b]" % chart.title).contains("fights")

func _charts() -> Array[Node]:
	return _results.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node.has_method("show_boxes"))

func _draw_frames() -> void:
	await await_idle_frame()
	await await_idle_frame()
