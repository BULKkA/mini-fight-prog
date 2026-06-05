extends Control

@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D

func set_sprite(Effect):
	Anim.play(GlobalVar.Effect.keys()[Effect])
