extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hud_instance = GlobalVar.InGamehud_scene.instantiate()
	get_tree().root.add_child(hud_instance)

func _process(delta: float) -> void:
	pass
