extends Node

var Current_scene_data
var InGamehud_scene = preload("res://scenes/ui/InGame_UI.tscn")
var Weapon_scene = load("res://scenes/combat/weapon.tscn")
var Player: CharacterBody2D
var Enemies: Dictionary = load("res://data/Enemy.tres").data
var Weapons: Dictionary = load("res://data/Weapons.tres").data

var Effects_data: Dictionary = load("res://data/Effects.tres").data
var Effect_scene = load("res://scenes/ui/effect.tscn")
var Effect_connect: Dictionary = load("res://data/Effect_connect.tres").data
var Effect_connect_data: Dictionary = load("res://data/Effect_connect_data.tres").data

enum Effect{
	NONE, 
	FIRE,
	FREEZE,
	POISON
}

signal NextWave(Wave)
signal LevelFinish()

signal SelectWeapon(weapon)
signal AddWeapon(weapon)
signal RemoveWeapon(weapon)
signal PlayerAttack(weapon, data)
signal SetHealth(health)
signal SetStamina(stamina)
