@tool
extends Control

## A bar or box chart: one slot per category, its series side by side or stacked. Hovering a category tells all its values
## ([method describe_hovered], for a rich tooltip that [signal hovered_changed] refreshes).

## The mouse moved onto another category, or off them
signal hovered_changed

const MARGIN: Vector4 = Vector4(44, 44, 8, 20)  # left, top (title and legend), right, bottom
## The chart's size at least; it grows with its row and is wider with more categories ([constant CATEGORY_WIDTH_MIN] each)
const SIZE_MIN: Vector2 = Vector2(340, 210)
const CATEGORY_WIDTH_MIN: float = 36.0
## A tilted name needs this many times the text's height beside the next; with less, only every few are named
const TILTED_ROOM_FACTOR: float = 1.5
const GRID_LINES: int = 4

var title: String
var categories: Array[String] = []
## The colour of each category's name, e.g. of the attribute a fighter fights with; none (or transparent): the theme's
var category_colors: Array[Color] = []
## An icon before each category's name (none: no icon), and the names shown under the bars (none: [member categories], which hovering names)
var category_icons: Array[Texture2D] = []:
	set(icons):
		category_icons = icons
		_fit_labels()
var category_labels: Array[String] = []:
	set(labels):
		category_labels = labels
		_fit_labels()
## {name: String, color: Color, values: Array[float]}, one value per category;
## as boxes {name, color, boxes: Array}, per category the 10th, 25th, 50th, 75th and 90th percentile ([] without data)
var series: Array[Dictionary] = []
var stacked: bool = false
var percent: bool = false
var boxed: bool = false
## Said first when a category is hovered: what the chart shows
var explanation: String = ""
## Said last for each category, e.g. how many fights it counts ("" for none)
var notes: Array[String] = []

var _hovered: int = -1
## Room below the plot beyond [constant MARGIN] for names tilted by 45° because they don't fit level; 0: level
var _tilted_room: float = 0.0

func _init() -> void:
	custom_minimum_size = SIZE_MIN
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_exited.connect(func() -> void: _set_hovered(-1))

func show_data(new_title: String, new_categories: Array[String], new_series: Array[Dictionary], is_stacked: bool = false, is_percent: bool = false) -> void:
	title = new_title
	categories = new_categories
	series = new_series
	stacked = is_stacked
	percent = is_percent
	boxed = false
	custom_minimum_size.x = maxf(SIZE_MIN.x, MARGIN.x + MARGIN.z + categories.size() * CATEGORY_WIDTH_MIN)
	_fit_labels()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: _fit_labels()

## Level names if each fits its room, else tilted by 45°, with the chart that much higher so the plot keeps its height
func _fit_labels() -> void:
	if categories.is_empty() or size.x <= 0.0: return
	var font: Font = get_theme_default_font()
	var text_size: int = get_theme_default_font_size() - 2
	var room: float = _get_label_step() * (size.x - MARGIN.x - MARGIN.z) / categories.size()
	var widest: float = 0.0
	for index: int in categories.size(): widest = maxf(widest, _get_label_width(index, font, text_size))
	var tilted_room: float = 0.0 if widest <= room - 4.0 else ceilf((widest + text_size) * 0.71)
	if is_equal_approx(tilted_room, _tilted_room): return
	_tilted_room = tilted_room
	custom_minimum_size.y = SIZE_MIN.y + tilted_room
	queue_redraw()

## Every how many categories one is named: each, unless even tilted names would run into each other
func _get_label_step() -> int:
	var slot: float = maxf(size.x - MARGIN.x - MARGIN.z, 1.0) / maxf(categories.size(), 1.0)
	return maxi(1, ceili((get_theme_default_font_size() - 2) * TILTED_ROOM_FACTOR / slot))

func _get_label(index: int) -> String: return category_labels[index] if index < category_labels.size() else categories[index]

func _get_label_width(index: int, font: Font, text_size: int) -> float:
	var icon_width: float = text_size + 2.0 if index < category_icons.size() and category_icons[index] != null else 0.0
	return font.get_string_size(_get_label(index), HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x + icon_width

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
	var label_step: int = _get_label_step()
	for index: int in categories.size():
		var bars: Array[Rect2] = _get_bars(index)
		for series_index: int in bars.size():
			if boxed: _draw_box(bars[series_index], series[series_index]["boxes"][index], series[series_index]["color"])
			else: draw_rect(bars[series_index], series[series_index]["color"])
		if index % label_step == 0:
			_draw_category(index, Rect2(plot.position.x + slot * index, plot.end.y, slot * label_step, font_size + 2), font, font_size - 2, text_color)

## Its name in [param area] under its bars, after its icon if it has one, in its colour if it has one: level and centred, or tilted by 45° and
## ending under the middle of its bars when the names don't fit level
func _draw_category(index: int, area: Rect2, font: Font, text_size: int, text_color: Color) -> void:
	var color: Color = category_colors[index] if index < category_colors.size() and category_colors[index].a > 0.0 else text_color
	var label: String = _get_label(index)
	var icon: Texture2D = category_icons[index] if index < category_icons.size() else null
	var icon_size: float = text_size if icon != null else 0.0
	var gap: float = 2.0 if icon != null else 0.0
	var width: float = _get_label_width(index, font, text_size)
	if _tilted_room > 0.0:
		var slot_middle: float = area.position.x + (area.size.x / _get_label_step()) / 2.0
		draw_set_transform(Vector2(slot_middle, area.position.y + 6.0), -PI / 4.0)
		if icon != null: draw_texture_rect(icon, Rect2(-width, -icon_size * 0.5, icon_size, icon_size), false, color)
		draw_string(font, Vector2(-width + icon_size + gap, text_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, color)
		draw_set_transform(Vector2.ZERO)
		return
	var start: float = area.position.x + maxf(0.0, (area.size.x - width) / 2.0)
	var baseline: float = area.end.y
	if icon != null: draw_texture_rect(icon, Rect2(start, baseline - icon_size + 1, icon_size, icon_size), false, color)
	draw_string(font, Vector2(start + icon_size + gap, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, maxf(area.size.x - icon_size - gap, 1.0), text_size, color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: _set_hovered(_get_category_at((event as InputEventMouseMotion).position))

func _set_hovered(index: int) -> void:
	if index == _hovered: return
	_hovered = index
	hovered_changed.emit()

## The category under [param at_position], -1 outside the plot
func _get_category_at(at_position: Vector2) -> int:
	var plot: Rect2 = _get_plot_rect()
	if categories.is_empty() or not plot.grow_individual(0, MARGIN.y, 0, MARGIN.w + _tilted_room).has_point(at_position): return -1
	return clampi(floori((at_position.x - plot.position.x) / (plot.size.x / categories.size())), 0, categories.size() - 1)

## Everything about the hovered category: each series' value (its percentiles as boxes), then its note; "" when none is hovered
func describe_hovered() -> String:
	if _hovered < 0 or _hovered >= categories.size(): return ""
	var lines: Array[String] = ["[b]%s[/b] — %s" % [title, categories[_hovered]]]
	if not explanation.is_empty(): lines.append("[color=#ffffff99]%s[/color]" % explanation)
	for entry: Dictionary in series:
		var swatch: String = "[color=%s]■[/color] %s" % [(entry["color"] as Color).to_html(), entry["name"]]
		if not boxed:
			lines.append("%s: %s" % [swatch, _format(entry["values"][_hovered])])
			continue
		var box: Array = entry["boxes"][_hovered]
		if box.is_empty(): lines.append("%s: no fights" % swatch)
		else: lines.append("%s: median %s, middle half %s–%s, 10–90%%: %s–%s" % [swatch, _format(box[2]), _format(box[1]), _format(box[3]), _format(box[0]), _format(box[4])])
	if _hovered < notes.size() and not notes[_hovered].is_empty(): lines.append("[color=#ffffff99]%s[/color]" % notes[_hovered])
	return "\n".join(lines)

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
	return Rect2(MARGIN.x, MARGIN.y, size.x - MARGIN.x - MARGIN.z, size.y - MARGIN.y - MARGIN.w - _tilted_room)

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
