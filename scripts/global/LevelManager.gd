extends Node

@onready var LevelsGrid: GridContainer = $CenterContainer/LevelsGrid
@onready var levels = load("res://data/levels/Levels.tres")

func _ready() -> void:
	for level in levels.data:
		var button = Button.new()
		button.text = level.name
		button.pressed.connect(_on_level_pressed.bind(level.id))
		LevelsGrid.add_child(button)

func _on_level_pressed(level_id):
	var level = levels.data[level_id]
	OpenSceneWithData(level.link, level.level_data)

func OpenSceneWithData(Scene, Data):
	var new_scene = load(Scene)
	var scene_data = load(Data)
	InitializeScene(new_scene, scene_data.data)
	get_tree().change_scene_to_packed(new_scene)

func InitializeScene(scene, data):
	SpawnManager.setScene(scene.instantiate())
	SpawnManager.SpawnPlayer(data.player_spawn_position)
	SpawnManager.StartWaves(data.waves_count, data.waves)
	
	
