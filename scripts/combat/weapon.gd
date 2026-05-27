extends Node2D

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var CollectBox: Area2D = $CollectBox
var AnimSprite2D: AnimatedSprite2D
var current_weapon_type
var data
var player
var currentCollision
var OnGround = true

enum {
	NONE,
	FIRE,
	ISE,
	POISON
}

func _ready() -> void:
	pass
	
func set_weapon_data(weapon_type, weapon_data):
	data = weapon_data
	currentCollision = get_node("AttackBox").get_node(weapon_data.id)
	AnimSprite2D = get_node("AttackBox/AnimatedSprite2D")
	AnimSprite2D.play(weapon_data.id)

func attack(direction: Vector2) -> void:

	data["uses"] -= 1
	GlobalVar.PlayerAttack.emit(self, data)
	rotation = direction.angle() + PI / 2
	self.visible = true
	AnimSprite2D.play(data.id)
	currentCollision.disabled = false
	AnimPlayer.play("Attack")
	await AnimPlayer.animation_finished
	currentCollision.disabled = true
	self.visible = false
	if data["uses"] <= 0:
		GlobalVar.RemoveWeapon.emit(self)
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
	if player.weapons.size <= 4:
		call_deferred("add_weapon", self)

func add_weapon(weapon):
	if OnGround:
		OnGround = false
		GlobalVar.AddWeapon.emit(weapon)
		

func remove_weapon(weapon):
	GlobalVar.RemoveWeapon.emit(weapon)

func set_monitoring(flag):
	CollectBox.set_deferred("monitorable", flag)
	
