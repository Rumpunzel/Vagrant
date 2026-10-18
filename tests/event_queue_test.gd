extends GdUnitTestSuite

## EventQueue: events run in order, delays and awaiting events block the ones behind them.

var _queue: EventQueue
var _log: Array[String]

func before_test() -> void:
	_queue = auto_free(EventQueue.new())
	_queue.one_shot = true
	add_child(_queue)
	_log = []

func test_events_run_in_order() -> void:
	_queue.queue_callable(func() -> void: _log.append("a"))
	_queue.queue_callable(func() -> void: _log.append("b"))
	assert_array(_log).is_equal(["a", "b"])

func test_delay_holds_back_later_events() -> void:
	_queue.queue_callable(func() -> void: _log.append("a"))
	_queue.queue_delay(0.1)
	_queue.queue_callable(func() -> void: _log.append("b"))
	assert_array(_log).is_equal(["a"])
	await await_millis(200)
	assert_array(_log).is_equal(["a", "b"])

func test_awaiting_event_holds_back_events_queued_later() -> void:
	var gate: Gate = Gate.new()
	_queue.queue_callable(func() -> void:
		_log.append("start")
		await gate.opened
		_log.append("end")
	)
	# Queued while the first event waits (and the timer is not running)
	_queue.queue_callable(func() -> void: _log.append("next"))
	await await_millis(50)
	assert_array(_log).is_equal(["start"])
	gate.opened.emit()
	await await_millis(50)
	assert_array(_log).is_equal(["start", "end", "next"])

func test_skip_ends_a_delay_early() -> void:
	_queue.queue_delay(10.0)
	_queue.queue_callable(func() -> void: _log.append("after"))
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = false
	Input.parse_input_event(event)
	await await_millis(100)
	assert_array(_log).is_equal(["after"])

class Gate extends RefCounted:
	signal opened
