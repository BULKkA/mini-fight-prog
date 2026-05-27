extends Control

@onready var AnimPlayer = $AnimationPlayer
@onready var Anim = $ROOT/AnimatedSprite2D
@onready var Damage: Label = $ROOT/Damage
@onready var Uses: Label = $ROOT/Uses

func _ready() -> void:
	AnimPlayer.play("Create")

func SetData(Data):
	Damage.text = String.num_int64(Data.damage)
	Uses.text = String.num_int64(Data.uses)
	Anim.play(Data.id)

func playerAttack():
	pass

func activate():
	AnimPlayer.play("Activate")

func  deactivate():
	AnimPlayer.play("Deactivate")
