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
	InitializeScene(new_scene, load(Data))
	get_tree().change_scene_to_packed(new_scene)

func InitializeScene(scene, data):
	SpawnManager.set_scene(scene)
	SpawnManager.SpawnPlayer(data.player_spawn_position)
	
	
