@tool
extends Control

## A bar chart: one slot per category, its series side by side or stacked. Hover a bar for its value.

const MARGIN: Vector4 = Vector4(44, 44, 8, 20)  # left, top (title and legend), right, bottom
const GRID_LINES: int = 4

var title: String
var categories: Array[String] = []
## {name: String, color: Color, values: Array[float]}, one value per category
var series: Array[Dictionary] = []
var stacked: bool = false
var percent: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(340, 210)
	mouse_filter = Control.MOUSE_FILTER_PASS

func show_data(new_title: String, new_categories: Array[String], new_series: Array[Dictionary], is_stacked: bool = false, is_percent: bool = false) -> void:
	title = new_title
	categories = new_categories
	series = new_series
	stacked = is_stacked
	percent = is_percent
	queue_redraw()

func _draw() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var text_color: Color = get_theme_color("font_color", "Label")
	draw_string(font, Vector2(4, font_size + 2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	_draw_legend(font, font_size)
	var plot: Rect2 = _get_plot_rect()
	var top: float = _get_top()
	for line: int in GRID_LINES + 1:
		var value: float = top * line / GRID_LINES
		var y: float = plot.end.y - plot.size.y * line / GRID_LINES
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(text_color, 0.15))
		draw_string(font, Vector2(2, y + font_size * 0.35), _format(value), HORIZONTAL_ALIGNMENT_RIGHT, MARGIN.x - 6, font_size - 2, Color(text_color, 0.6))
	if categories.is_empty(): return
	var slot: float = plot.size.x / categories.size()
	var label_step: int = ceili(categories.size() * 40.0 / plot.size.x)
	for index: int in categories.size():
		var bars: Array[Rect2] = _get_bars(index)
		for series_index: int in bars.size(): draw_rect(bars[series_index], series[series_index]["color"])
		if index % label_step == 0:
			draw_string(font, Vector2(plot.position.x + slot * index, plot.end.y + font_size + 2), categories[index], HORIZONTAL_ALIGNMENT_CENTER, slot * label_step, font_size - 2, text_color)

func _get_tooltip(at_position: Vector2) -> String:
	for index: int in categories.size():
		var bars: Array[Rect2] = _get_bars(index)
		for series_index: int in bars.size():
			if bars[series_index].grow(1).has_point(at_position):
				return "%s — %s: %s" % [categories[index], series[series_index]["name"], _format(series[series_index]["values"][index])]
	return ""

## Below the title, left to right
func _draw_legend(font: Font, font_size: int) -> void:
	var x: float = 4.0
	var y: float = font_size * 2.0 + 6.0
	for entry: Dictionary in series:
		draw_rect(Rect2(x, y - 9, 9, 9), entry["color"])
		x += 13
		draw_string(font, Vector2(x, y), entry["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, get_theme_color("font_color", "Label"))
		x += font.get_string_size(entry["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x + 12

## One rectangle per series for category [param index]
func _get_bars(index: int) -> Array[Rect2]:
	var plot: Rect2 = _get_plot_rect()
	var slot: float = plot.size.x / categories.size()
	var top: float = _get_top()
	var bars: Array[Rect2] = []
	var base: float = 0.0
	for series_index: int in series.size():
		var value: float = maxf(float(series[series_index]["values"][index]), 0.0)
		var height: float = plot.size.y * value / top
		if stacked:
			bars.append(Rect2(plot.position.x + slot * (index + 0.15), plot.end.y - base - height, slot * 0.7, height))
			base += height
		else:
			var width: float = slot * 0.8 / series.size()
			bars.append(Rect2(plot.position.x + slot * (index + 0.1) + width * series_index, plot.end.y - height, width, height))
	return bars

func _get_plot_rect() -> Rect2:
	return Rect2(MARGIN.x, MARGIN.y, size.x - MARGIN.x - MARGIN.z, size.y - MARGIN.y - MARGIN.w)

## The value at the top of the chart: 100% for shares, else a round number above the highest bar
func _get_top() -> float:
	if percent: return 1.0
	var highest: float = 0.0
	for index: int in categories.size():
		var total: float = 0.0
		for entry: Dictionary in series:
			var value: float = float(entry["values"][index])
			total = total + value if stacked else maxf(total, value)
		highest = maxf(highest, total)
	if highest <= 0.0: return 1.0
	var magnitude: float = pow(10.0, floorf(log(highest) / log(10.0)))
	for step: float in [1.0, 2.0, 2.5, 5.0, 10.0]:
		if step * magnitude >= highest: return step * magnitude
	return highest

func _format(value: float) -> String:
	if percent: return "%d%%" % roundi(value * 100.0)
	return str(snappedf(value, 0.01))
