@tool
extends VBoxContainer

## One simulated fight: how threat, breath and injuries went exchange by exchange, then what the game told about each exchange.
## The fighters' names link to their cards, each exchange's heading to how it stood after it.

const FightLabChart: GDScript = preload("uid://bq8r7sebmls8p")  # fight_lab_chart.gd
const YOU: Color = Color("42a5f5")
const FOE: Color = Color("e53935")

## What the tooltips say; set by the dock
var tooltips: FightLabTooltips = FightLabTooltips.new()

var _heading: RichTextLabel
var _timeline: HFlowContainer
var _log: RichTextLabel
var _linked: bool = false

func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_heading = RichTextLabel.new()
	_heading.bbcode_enabled = true
	_heading.fit_content = true
	_heading.scroll_active = false
	_heading.add_theme_font_size_override("normal_font_size", get_theme_default_font_size() + 3)
	add_child(_heading)
	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	_timeline = HFlowContainer.new()
	_timeline.custom_minimum_size.x = 360
	_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_timeline)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.selection_enabled = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size.x = 360
	split.add_child(_log)

## [param result] as [method FightLabRun.execute] returns it for one fight
func show_result(result: Dictionary) -> void:
	var fight: Dictionary = result["fight"]
	var record: Dictionary = fight["record"]
	var a: int = fight["a"]
	var b: int = fight["b"]
	var character: String = result["side_a"][a]
	var monster: String = result["side_b"][b]
	var exchange_log: Array = record["log"]
	tooltips.result = result
	tooltips.exchange_log = exchange_log
	if not _linked:
		tooltips.attach_links(_heading)
		tooltips.attach_links(_log)
		_linked = true
	_heading.text = "%s vs %s: %s after %d exchange%s" % [tooltips.link_fighter("a", a), tooltips.link_fighter("b", b), record["outcome"], exchange_log.size(), "" if exchange_log.size() == 1 else "s"]
	var categories: Array[String] = []
	for index: int in exchange_log.size(): categories.append(str(index + 1))
	for child: Node in _timeline.get_children(): child.queue_free()
	_add_chart("Threat per exchange", categories, [_series(exchange_log, character, YOU, "threat"), _series(exchange_log, monster, FOE, "foe_threat")])
	_add_chart("Breath dice after each exchange", categories, [_series(exchange_log, character, YOU, "breath"), _series(exchange_log, monster, FOE, "foe_breath")])
	_add_chart("Injuries after each exchange", categories, [_series(exchange_log, character, YOU, "injuries"), _series(exchange_log, monster, FOE, "foe_injuries")])
	var text: String = ""
	for index: int in exchange_log.size():
		text += "[url=exchange:%d][b]Exchange %d[/b][/url]%s" % [index + 1, index + 1, exchange_log[index]["text"]]
	_log.text = text

func _add_chart(title: String, categories: Array[String], series: Array[Dictionary]) -> void:
	var chart: Control = FightLabChart.new()
	_timeline.add_child(chart)
	chart.show_data(title, categories, series)
	var trigger: RichTooltipTrigger = tooltips.attach(chart, Callable(chart, &"describe_hovered"))
	chart.connect(&"hovered_changed", trigger.refresh)

static func _series(exchange_log: Array, label: String, color: Color, key: String) -> Dictionary:
	var values: Array[float] = []
	for entry: Dictionary in exchange_log: values.append(float(entry[key]))
	return {"name": label, "color": color, "values": values}
