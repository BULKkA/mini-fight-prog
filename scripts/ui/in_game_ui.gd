extends Control

var weapons: Dictionary = {}
var weapon_card_scene = load("res://scenes/ui/WeaponCard.tscn")
var currentWeapon:
	set (value):
		if currentWeapon != value and currentWeapon != null:
			currentWeapon.deactivate()
		currentWeapon = value
		if value != null:
			currentWeapon.activate()

@onready var Inventory = $Inventory

func _ready() -> void:
	ConnectSignals()

func ConnectSignals():
	GlobalVar.AddWeapon.connect(add_weapon)
	GlobalVar.RemoveWeapon.connect(remove_weapon)
	GlobalVar.SelectWeapon.connect(select_weapon)
	GlobalVar.PlayerAttack.connect(player_attack)

func add_weapon(weapon):
	var New_Weapon = weapon_card_scene.instantiate()
	Inventory.add_child(New_Weapon)
	Inventory.move_child(New_Weapon, Inventory.get_child_count() - 2)
	New_Weapon.SetData(weapon.data)
	if weapons.size() == 0:
		currentWeapon = New_Weapon
	weapons[weapon] = New_Weapon

func remove_weapon(weapon):
	if weapon == currentWeapon:
		if weapons.size() > 1:
			currentWeapon = weapons[0] if weapons[0] != weapon else weapons[1]
		else:
			currentWeapon = null
	weapons[weapon].queue_free()
	weapons.erase(weapon)

func select_weapon(weapon):
	var weapon_card = weapons[weapon]
	currentWeapon = weapon_card

func player_attack(weapon, data):
	weapons[weapon].SetData(data)
	
