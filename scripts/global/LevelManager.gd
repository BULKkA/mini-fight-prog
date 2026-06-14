extends Node

const SAVE_PATH := "user://level_save.json"
const DEFAULT_LEVEL_ID := 1

@onready var levels = load("res://data/levels/Levels.tres")

var Current_level_id = null
var debug_mode = false

func _ready():
	Current_level_id = load_level_id()
	GlobalVar.LevelFinish.connect(finish_level)

func start_level():
	if debug_mode:
		Current_level_id = 0
	var level = levels.data[Current_level_id]
	OpenSceneWithData(level.link, level.level_data)

func finish_level():
	Current_level_id += 1
	save_level_id(Current_level_id)
	start_level()

func OpenSceneWithData(Scene, Data):
	get_tree().change_scene_to_packed(load(Scene))
	GlobalVar.Current_scene_data = load(Data).data

func save_level_id(level_id: int) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	var data = {
		"level_id": level_id
	}

	file.store_string(JSON.stringify(data))
	file.close()

func load_level_id() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		save_level_id(DEFAULT_LEVEL_ID)
		return DEFAULT_LEVEL_ID

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		save_level_id(DEFAULT_LEVEL_ID)
		return DEFAULT_LEVEL_ID

	var data = json.data

	if not data.has("level_id"):
		save_level_id(DEFAULT_LEVEL_ID)
		return DEFAULT_LEVEL_ID

	return int(data["level_id"])
