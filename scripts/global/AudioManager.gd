extends Node

var music_player: AudioStreamPlayer

enum SFX {
	HIT
}

var sounds = {
	#SFX.HIT: preload("res://sfx/hit.wav"),
	#SFX.EXPLOSION: preload("res://sfx/explosion.wav"),
	#SFX.HEAL: preload("res://sfx/heal.wav")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func play_music(stream: SFX) -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	music_player.stream = sounds[stream]
	music_player.play()
