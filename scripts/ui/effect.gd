extends Control

func set_sprite(Effect):
	$AnimatedSprite2D.play(GlobalVar.Effect.keys()[Effect])
