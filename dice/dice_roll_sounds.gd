extends AudioStreamPlayer

@export var _stagger_delay_msec := 20
@export var _pitch_randomness_perc := 20

var _last_sound_played_at_msec := 0

@onready var _dice_polyphony := get_stream_playback()

func _enter_tree() -> void:
	Rules.d4.rolled.connect(_on_die_type_rolled)
	Rules.d6.rolled.connect(_on_die_type_rolled)
	Rules.d8.rolled.connect(_on_die_type_rolled)
	Rules.d10.rolled.connect(_on_die_type_rolled)
	Rules.d12.rolled.connect(_on_die_type_rolled)

func _on_die_type_rolled(_die_type: DieType, _result: int, roll_sound: AudioStream) -> void:
	if roll_sound == null: return
	var msec_since_last_sound := Time.get_ticks_msec() - _last_sound_played_at_msec
	var delay_msec := maxi(_stagger_delay_msec - msec_since_last_sound, 0)
	_last_sound_played_at_msec = Time.get_ticks_msec() + delay_msec
	if delay_msec > 0: await get_tree().create_timer(delay_msec / 1000.0).timeout
	var random_pitch := randf_range(1.0 - _pitch_randomness_perc / 100.0, 1.0 + _pitch_randomness_perc / 100.0)
	_dice_polyphony.play_stream(roll_sound, 0.0, 0.0, random_pitch)
