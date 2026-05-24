extends Node2D

var damage = 1
var strength = 50
var effect = NONE

enum {
	NONE,
	FIRE,
	ISE,
	POISON
}

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func set_weapon_data(weapon_type):
	damage = weapon_type.damage
	strength = weapon_type.strength
	effect = weapon_type.effect
	
func _on_attack_box_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func attackBody(body):
	var direction = (body.global_position - global_position).normalized()
	var knockback := {
		"direction": direction,
		"strength": strength
	}
	body.take_hit(damage, knockback)
