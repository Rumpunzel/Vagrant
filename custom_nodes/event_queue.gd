class_name EventQueue
extends SkippableTimer

var _queue: Array[Event] = []

func queue(delay: float, callable: Callable) -> void:
	queue_delay(delay)
	queue_callable(callable)

func queue_delay(delay: float) -> void:
	_queue_event(_create_delay_event(delay))

func queue_callable(callable: Callable) -> void:
	_queue_event(_create_event(callable))

func _queue_event(event: Event) -> void:
	_queue.push_back(event)
	if is_stopped(): _execute_next_event()

func _execute_next_event() -> void:
	assert(not _queue.is_empty())
	var next_event: Event = _queue.pop_front()
	await next_event.execute()
	if not _queue.is_empty(): _execute_next_event()

func _create_event(callable: Callable) -> Event:
	return Event.new(callable)

func _create_delay_event(delay: float) -> Event:
	return Event.new(func() -> void: start(delay); await timeout)

class Event extends RefCounted:
	var _callable: Callable
	
	func _init(callable: Callable) -> void:
		assert(callable)
		_callable = callable
	
	func execute() -> Variant:
		return await _callable.call()
