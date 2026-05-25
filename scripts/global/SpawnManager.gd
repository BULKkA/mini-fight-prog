extends Node

@onready var SpawnPoints: Node2D = $SpawnPoints
var currentWave: int

var enemies
var weapons 
var Level_SpawnPoints = SpawnPoints.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = load("res://data/Enemy.tres").data
	weapons = load("res://data/Weapons.tres").data

func _process(delta: float) -> void:
	pass

func SpawnWeapon(Weapon) -> void:
	pass

func SpawnEnemy(Enemy) -> void:
	pass

func SpawnPlayer(position) -> void:
	var player = load("res://scenes/combat/Player.tscn").instantiate()
	player.position = Vector2(position[0], position[1])
	add_child(player)

func StartWawes(waves_count, Waves):
	var firstWave = Waves[0]
	
	for enemy in firstWave.enemies:
		await get_tree().create_timer(enemy.spawn_delay).timeout
		SpawnEnemy(enemy.type)
		
	for enemy in firstWave.enemies:
		await get_tree().create_timer(enemy.spawn_delay).timeout
		SpawnEnemy(enemy.type)
	
	
	
	
	
	
