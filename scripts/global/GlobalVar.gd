extends Node

var Current_scene_data
var InGamehud_scene = preload("res://scenes/ui/InGame_UI.tscn")
var Weapon_scene = load("res://scenes/combat/weapon.tscn")
var Player: CharacterBody2D
var Enemies: Dictionary = load("res://data/Enemy.tres").data
var Weapons: Dictionary = load("res://data/Weapons.tres").data

signal SelectWeapon(weapon)
signal AddWeapon(weapon)
signal RemoveWeapon(weapon)
signal PlayerAttack(weapon, data)
