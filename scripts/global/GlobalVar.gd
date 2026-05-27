extends Node

var Current_scene_data
var InGamehud_scene = preload("res://scenes/ui/InGame_UI.tscn")

signal SelectWeapon(weapon)
signal AddWeapon(weapon)
signal RemoveWeapon(weapon)
signal PlayerAttack(weapon, data)
