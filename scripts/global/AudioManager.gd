extends Node


enum SFX {
	HIT
}

var sounds = {
	#SFX.HIT: preload("res://sfx/hit.wav"),
	#SFX.EXPLOSION: preload("res://sfx/explosion.wav"),
	#SFX.HEAL: preload("res://sfx/heal.wav")
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

signal PlaySFX(sfx)
signal PlayMusic(music)

func _ready():

	#Плеер для музыки
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	#Дорожки для эффектов (заранее создаем несколько, чтоб не создавать и уничтожать их каждый раз, 
	#и ограничить количество одновременно воспроизводимых эффектов)
	for i in 16:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	#писюньчики

	PlaySFX.connect(play_sfx)
	PlayMusic.connect(play_music)

func play_music(stream: SFX):
	music_player.stream = sounds[stream]
	music_player.play()

func play_sfx(stream: SFX):
	for player in sfx_players:
		if not player.playing:
			player.stream = sounds[stream]
			player.play()
			return
