extends Node

var current_scene
var weaponSpawnPoints = []
var enemySpawnPoints = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func SpawnWeapon(Weapon) -> void:
	pass

func SpawnEnemy(Enemy) -> void:
	pass

func SpawnPlayer(position) -> void:
	player = load("res://scenes/Player/Player.tscn").instance()
	player.position = position
	current_scene.add_child(player)

func set_scene(scene):
	current_scene = scene

