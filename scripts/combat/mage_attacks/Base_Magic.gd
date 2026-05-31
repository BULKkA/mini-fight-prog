extends Node
class_name Magic

var target
var Strength
var Damage
var Effect
var Name

@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var HitBox: Area2D = $HitBox
@onready var AttackBox: Area2D = $AttackBox

func _ready() -> void:
	animation_sprite.play("Start")
	await animation_sprite.animation_finished
	
	animation_sprite.play("Attack")
	AnimPlayer.play("Attack")
	await animation_sprite.animation_finished
	queue_free()

func _on_attack_box_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	var direction = (body.global_position - self.global_position).normalized()
	var knockback := {
		"direction": direction,
		"strength": Strength
	}
	body.take_hit(Damage, knockback, GlobalVar.Effect[Effect])
