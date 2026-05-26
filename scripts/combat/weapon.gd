extends Node2D

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var CollectBox: Area2D = $CollectBox
var AnimSprite2D: AnimatedSprite2D
var current_weapon_type
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
	
func set_weapon_data(weapon_type, weapon_data, set_uses):
	data = weapon_data
	current_weapon_type = weapon_type
	uses = set_uses 
	currentCollision = get_node("AttackBox").get_node(weapon_type)
	AnimSprite2D = get_node("AttackBox/AnimatedSprite2D")
	AnimSprite2D.play(weapon_type)

func attack(direction: Vector2) -> void:

	uses -= 1
	rotation = direction.angle()
	AnimSprite2D.play(current_weapon_type)

	currentCollision.Disable = false
	AnimPlayer.play("Attack")
	await AnimPlayer.animation_finished
	currentCollision.disable = true

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
	
func Interact(in_player):
	player = in_player
	player.call_deferred("add_weapon", self)
	
func set_monitoring(flag):
	CollectBox.set_deferred("monitorable", flag)



	
