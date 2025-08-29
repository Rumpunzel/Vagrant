extends AudioStreamPlayer

@export var _delay_window_mean_msec: int = 100
@export var _delay_window_deviation_msec: int = 100
@export var _pitch_randomness_perc: int = 20

var _last_sound_played_at_msec: int = 0

var _dice_polyphony: AudioStreamPlaybackPolyphonic

func _ready() -> void:
	stream = AudioStreamPolyphonic.new()
	play()
	_dice_polyphony = get_stream_playback()
	Rules.d4.rolled.connect(_on_die_type_rolled)
	Rules.d6.rolled.connect(_on_die_type_rolled)
	Rules.d8.rolled.connect(_on_die_type_rolled)
	Rules.d10.rolled.connect(_on_die_type_rolled)
	Rules.d12.rolled.connect(_on_die_type_rolled)

func _on_die_type_rolled(_die_type: DieType, _result: int, roll_sound: AudioStream) -> void:
	if roll_sound == null: return
	var msec_since_last_sound: int = Time.get_ticks_msec() - _last_sound_played_at_msec
	_last_sound_played_at_msec = Time.get_ticks_msec()
	if msec_since_last_sound < _delay_window_mean_msec:
		var random_delay: float = randfn(_delay_window_mean_msec, _delay_window_deviation_msec)
		_last_sound_played_at_msec += int(random_delay)
		await get_tree().create_timer(random_delay / 1000.0).timeout
	var random_pitch: float = randf_range(1.0 - _pitch_randomness_perc / 100.0, 1.0 + _pitch_randomness_perc / 100.0)
	_dice_polyphony.play_stream(roll_sound, 0.0, 0.0, random_pitch)
