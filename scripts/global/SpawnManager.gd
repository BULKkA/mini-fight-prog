extends Node

var player
var enemies: Dictionary
var weapons: Dictionary 
var weapon_scene
var WeaponSpawners
var EnemySpawners

var current_scene

var WaveActivicy: bool = false

signal setSceneSignal(data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WeaponSpawners = get_tree().current_scene.get_node("WeaponSpawners").get_children()
	EnemySpawners = get_tree().current_scene.get_node("EnemySpawners").get_children()
	SpawnPlayer(GlobalVar.Current_scene_data.player_spawn_position)
	StartWaves(GlobalVar.Current_scene_data.waves_count, GlobalVar.Current_scene_data.waves) 

func spawn_weapons(weapons):
	while WaveActivicy: 
		for weapon in weapons:
			await get_tree().create_timer(weapon.spawn_delay).timeout
			if WaveActivicy:
				return
			SpawnWeapon(weapon)

func SpawnWeapon(Weapon_Spawn_Data) -> void:
	var WeaponSpawner = WeaponSpawners[randi() % WeaponSpawners.size()]	
	var weapon_data = GlobalVar.Weapons[Weapon_Spawn_Data.type]
	var weapon = GlobalVar.Weapon_scene.instantiate()
	weapon_data["Uses"] = Weapon_Spawn_Data.Uses 
	weapon.set_weapon_data(Weapon_Spawn_Data.type, weapon_data)
	weapon.global_position = WeaponSpawner.global_position
	get_node("Weapon").add_child(weapon)

func spawn_enemies(enemies):
	for enemy in enemies:
		for i in range(enemy.count):
			await get_tree().create_timer(enemy.spawn_delay).timeout
			SpawnEnemy(enemy.type)
	WaveActivicy = false


func SpawnEnemy(Enemy) -> void:
	var EnemySpawner = EnemySpawners[randi() % EnemySpawners.size()]
	var enemy_data = GlobalVar.Enemies[Enemy]
	var enemy = load(enemy_data.Link).instantiate()
	enemy.global_position = EnemySpawner.global_position
	enemy.Init_Enemy(enemy_data)
	get_node("Enemy").add_child(enemy)

func SpawnPlayer(position) -> void:
	player = load("res://scenes/combat/Player.tscn").instantiate()
	player.global_position = Vector2(position[0], position[1])
	GlobalVar.Player = player
	add_child(player)

func StartWaves(waves_count, Waves):
	for wave in Waves:
		WaveActivicy = true
		spawn_enemies(wave.enemies)
		spawn_weapons(wave.weapons) 
		await wave_ended()
		ClearWaveObject()
		await get_tree().create_timer(wave.wave_delay).timeout
		GlobalVar.NextWave.emit()
	GlobalVar.LevelFinish.emit()
	
	
func wave_ended():
	while WaveActivicy or get_node("Enemy").get_child_count() > 0:
		await get_tree().process_frame

func ClearWaveObject():
	for child in get_node("Weapon").get_children():
		child.queue_free()
