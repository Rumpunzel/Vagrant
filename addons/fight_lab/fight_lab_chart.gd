@tool
extends Control

## A bar or box chart: one slot per category, its series side by side or stacked. Hover a bar or box for its values.

const MARGIN: Vector4 = Vector4(44, 44, 8, 20)  # left, top (title and legend), right, bottom
const GRID_LINES: int = 4

var title: String
var categories: Array[String] = []
## {name: String, color: Color, values: Array[float]}, one value per category;
## as boxes {name, color, boxes: Array}, per category the 10th, 25th, 50th, 75th and 90th percentile ([] without data)
var series: Array[Dictionary] = []
var stacked: bool = false
var percent: bool = false
var boxed: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(340, 210)
	mouse_filter = Control.MOUSE_FILTER_PASS

func show_data(new_title: String, new_categories: Array[String], new_series: Array[Dictionary], is_stacked: bool = false, is_percent: bool = false) -> void:
	title = new_title
	categories = new_categories
	series = new_series
	stacked = is_stacked
	percent = is_percent
	boxed = false
	queue_redraw()

## Box plots: per category and series, the middle half as a box with the median, whiskers to the 10th and 90th percentile
func show_boxes(new_title: String, new_categories: Array[String], new_series: Array[Dictionary]) -> void:
	show_data(new_title, new_categories, new_series)
	boxed = true

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
		for series_index: int in bars.size():
			if boxed: _draw_box(bars[series_index], series[series_index]["boxes"][index], series[series_index]["color"])
			else: draw_rect(bars[series_index], series[series_index]["color"])
		if index % label_step == 0:
			draw_string(font, Vector2(plot.position.x + slot * index, plot.end.y + font_size + 2), categories[index], HORIZONTAL_ALIGNMENT_CENTER, slot * label_step, font_size - 2, text_color)

func _get_tooltip(at_position: Vector2) -> String:
	for index: int in categories.size():
		var bars: Array[Rect2] = _get_bars(index)
		for series_index: int in bars.size():
			if not bars[series_index].grow(1).has_point(at_position): continue
			if not boxed: return "%s — %s: %s" % [categories[index], series[series_index]["name"], _format(series[series_index]["values"][index])]
			var box: Array = series[series_index]["boxes"][index]
			if box.is_empty(): return "%s — %s: no fights" % [categories[index], series[series_index]["name"]]
			return "%s — %s: median %s, middle half %s–%s, 10–90%%: %s–%s" % [categories[index], series[series_index]["name"], _format(box[2]), _format(box[1]), _format(box[3]), _format(box[0]), _format(box[4])]
	return ""

## [param area] spans the whiskers; the box is the middle half, the line the median
func _draw_box(area: Rect2, box: Array, color: Color) -> void:
	if box.is_empty(): return
	var plot: Rect2 = _get_plot_rect()
	var top: float = _get_top()
	var center: float = area.get_center().x
	draw_line(Vector2(center, _get_y(box[0], plot, top)), Vector2(center, _get_y(box[4], plot, top)), color, 1.5)
	for whisker: float in [box[0], box[4]]: draw_line(Vector2(center - area.size.x * 0.25, _get_y(whisker, plot, top)), Vector2(center + area.size.x * 0.25, _get_y(whisker, plot, top)), color, 1.5)
	var box_rect: Rect2 = Rect2(area.position.x, _get_y(box[3], plot, top), area.size.x, maxf(_get_y(box[1], plot, top) - _get_y(box[3], plot, top), 2.0))
	draw_rect(box_rect, Color(color, 0.75))
	draw_line(Vector2(area.position.x, _get_y(box[2], plot, top)), Vector2(area.end.x, _get_y(box[2], plot, top)), Color.WHITE, 2.0)

static func _get_y(value: float, plot: Rect2, top: float) -> float:
	return plot.end.y - plot.size.y * maxf(value, 0.0) / top

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
		if boxed:
			var width_of_box: float = slot * 0.8 / series.size()
			var box: Array = series[series_index]["boxes"][index]
			var low: float = _get_y(box[0], plot, top) if not box.is_empty() else plot.end.y
			var high: float = _get_y(box[4], plot, top) if not box.is_empty() else plot.end.y
			bars.append(Rect2(plot.position.x + slot * (index + 0.1) + width_of_box * series_index, high, width_of_box, maxf(low - high, 2.0)))
			continue
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
			var value: float = (float(entry["boxes"][index][4]) if not entry["boxes"][index].is_empty() else 0.0) if boxed else float(entry["values"][index])
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
