extends Node

@onready var LevelsGrid: GridContainer = $LevelsGrid
@onready var levels = load("res://data/levels/Levels.tres")

func _ready() -> void:
	for level in levels:
		var button = Button.new()
		button.text = level.name
		button.pressed.connect(_on_level_pressed.bind(level.id))
		LevelsGrid.add_child(button)

func _on_level_pressed(level_id):
	levels[level_id]


func OpenSceneWithData(Scene, Data):
	pass
