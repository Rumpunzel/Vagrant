extends AudioStreamPlayer

@export var stagger_delay_ms := 2.0

var _time_since_last_sound := 0.0

func _enter_tree() -> void:
	Rules.d4.rolled.connect(_on_die_type_rolled)
	Rules.d6.rolled.connect(_on_die_type_rolled)
	Rules.d8.rolled.connect(_on_die_type_rolled)
	Rules.d10.rolled.connect(_on_die_type_rolled)
	Rules.d12.rolled.connect(_on_die_type_rolled)

func _process(delta: float) -> void:
	_time_since_last_sound = max(_time_since_last_sound - delta, 0.0)

func _on_die_type_rolled(_die_type: DieType, _result: int, roll_sound: AudioStream) -> void:
	if roll_sound == null: return
	var delay := _time_since_last_sound
	_time_since_last_sound += stagger_delay_ms / 1000.0
	await get_tree().create_timer(delay).timeout
	var dice_polyphony := get_stream_playback()
	dice_polyphony.play_stream(roll_sound)
