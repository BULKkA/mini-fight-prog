extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_box: Area2D = $AttackBox

var data
var uses: int
var player
var currentCollision

enum {
	NONE,
	FIRE,
	ISE,
	POISON
}

func _ready() -> void:
	pass 

func set_weapon_data(weapon_type):
	data = weapon_type
	currentCollision = attack_box.get_node(weapon_type.id)

func attack(direction: Vector2) -> void:
	uses -= 1
	rotation = direction.angle()
	sprite.play(data.animation_name)

	# активируем хитбокс
	attack_box.monitoring = true

	await get_tree().create_timer(0.2).timeout
	attack_box.monitoring = false

	if uses <= 0:
		queue_free()

func _on_attack_box_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func attackBody(body):
	var direction = (body.global_position - global_position).normalized()
	var knockback := {
		"direction": direction,
		"strength": data.strength
	}
	body.take_hit(data.damage, knockback)
	
	
	
