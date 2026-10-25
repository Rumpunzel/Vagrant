extends GdUnitTestSuite

## CollapsibleContainer: visibility and clipping follow its state, its sizing node is connected once.

var _container: CollapsibleContainer
var _content: Control

func before_test() -> void:
	_container = auto_free(CollapsibleContainer.new())
	_content = Control.new()
	_content.name = "Content"
	_content.custom_minimum_size = Vector2(100, 50)
	_container.add_child(_content)
	_container.starts_opened = false
	_container.hide_when_closed = true
	_container.start_with_clip_contents = false
	_container.tween_duration_sec = 0.05
	_container.sizing_node = NodePath("Content")

func test_starts_closed_and_hidden() -> void:
	await _add()
	assert_bool(_container.is_closed()).is_true()
	assert_bool(_container.visible).is_false()

func test_open_shows_and_a_finished_close_tween_hides() -> void:
	await _add()
	_container.open()
	assert_bool(_container.visible).is_true()
	assert_bool(_container.clip_contents).is_false()
	_container.close_tween()
	assert_bool(_container.visible).is_true()
	assert_bool(_container.clip_contents).is_true()
	await await_millis(300)
	assert_bool(_container.is_closed()).is_true()
	assert_bool(_container.visible).is_false()

func test_closing_at_once_during_an_opening_tween_hides() -> void:
	await _add()
	_container.open_tween()
	assert_bool(_container.visible).is_true()
	_container.close()
	assert_bool(_container.visible).is_false()

func test_without_hide_when_closed_it_stays_visible() -> void:
	_container.hide_when_closed = false
	await _add()
	assert_bool(_container.visible).is_true()

func test_start_with_clip_contents_clips_when_opened_too() -> void:
	_container.start_with_clip_contents = true
	await _add()
	_container.open()
	assert_bool(_container.clip_contents).is_true()

func test_sizing_node_set_twice_before_ready_is_connected_once() -> void:
	_container.sizing_node = NodePath("")
	_container.sizing_node = NodePath("Content")
	await _add()
	var connections: Array = _content.resized.get_connections().filter(func(connection: Dictionary) -> bool: return connection["callable"].get_object() == _container)
	assert_int(connections.size()).is_equal(1)

## In the tree, past the deferred start
func _add() -> void:
	add_child(_container)
	await await_idle_frame()
	await await_idle_frame()
