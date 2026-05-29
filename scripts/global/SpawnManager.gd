extends Node

var player
var enemies: Dictionary
var weapons: Dictionary 
var weapon_scene
var Level_SpawnPoints

var current_scene

signal setSceneSignal(data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Level_SpawnPoints = get_tree().current_scene.get_node("SpawnPoints").get_children()
	SpawnPlayer(GlobalVar.Current_scene_data.player_spawn_position)
	StartWaves(GlobalVar.Current_scene_data.waves_count, GlobalVar.Current_scene_data.waves) 

func spawn_weapons(weapons):
	for weapon in weapons:
		await get_tree().create_timer(weapon.spawn_delay).timeout
		SpawnWeapon(weapon)

func SpawnWeapon(Weapon_Spawn_Data) -> void:
	var spawnPoint = Level_SpawnPoints[randi() % Level_SpawnPoints.size()]	
	var weapon_data = GlobalVar.Weapons[Weapon_Spawn_Data.type]
	var weapon = GlobalVar.Weapon_scene.instantiate()
	weapon_data["uses"] = Weapon_Spawn_Data.uses 
	weapon.set_weapon_data(Weapon_Spawn_Data.type, weapon_data)
	weapon.global_position = spawnPoint.global_position
	add_child(weapon)

func spawn_enemies(enemies):
	for enemy in enemies:
		for i in range(enemy.count):
			await get_tree().create_timer(enemy.spawn_delay).timeout
			SpawnEnemy(enemy.type)


func SpawnEnemy(Enemy) -> void:
	var spawnPoint = Level_SpawnPoints[randi() % Level_SpawnPoints.size()]
	var enemy_data = GlobalVar.Enemies[Enemy]
	var enemy = load(enemy_data.Link).instantiate()
	enemy.global_position = spawnPoint.global_position
	enemy.Init_Enemy(enemy_data)
	add_child(enemy)

func SpawnPlayer(position) -> void:
	player = load("res://scenes/combat/Player.tscn").instantiate()
	player.global_position = Vector2(position[0], position[1])
	GlobalVar.player = player
	add_child(player)

func StartWaves(waves_count, Waves):
	for wave in Waves:
		spawn_enemies(wave.enemies)
		spawn_weapons(wave.weapons) 
		await get_tree().create_timer(wave.wave_delay).timeout
	
	
	
	
	
