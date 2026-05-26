extends Node

var currentScene
var currentWave: int

var player
var enemies: Dictionary
var weapons: Dictionary 
var weapon_scene
var Level_SpawnPoints: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = load("res://data/Enemy.tres").data
	weapons = load("res://data/Weapons.tres").data
	weapon_scene = load("res://scenes/combat/Weapon.tscn")

func _process(delta: float) -> void:
	pass

func setScene(Scene):
	currentScene = Scene
	Level_SpawnPoints = currentScene.get_node("SpawnPoints").get_children()	

func SpawnWeapon(Weapon) -> void:
	var spawnPoint = Level_SpawnPoints[randi() % Level_SpawnPoints.size()]	
	var weapon_data = weapons[Weapon]
	var weapon = weapon_scene.instantiate()
	weapon.set_weapon_data(Weapon, weapon_data, 2)
	weapon.global_position = spawnPoint.global_position
	add_child(weapon)


func SpawnEnemy(Enemy) -> void:
	var spawnPoint = Level_SpawnPoints[randi() % Level_SpawnPoints.size()]
	var enemy = load(enemies[Enemy].Link).instantiate()
	enemy.global_position = spawnPoint.global_position
	add_child(enemy)

func SpawnPlayer(position) -> void:
	player = load("res://scenes/combat/Player.tscn").instantiate()
	player.global_position = Vector2(position[0], position[1])
	add_child(player)

func StartWaves(waves_count, Waves):
	var firstWave = Waves[0]
	
	for enemy in firstWave.enemies:
		await get_tree().create_timer(enemy.spawn_delay).timeout
		SpawnEnemy(enemy.type)
		
	for weapons in firstWave.weapons:
		await get_tree().create_timer(weapons.spawn_delay).timeout
		SpawnWeapon(weapons.type)
	
	
	
	
	
	
