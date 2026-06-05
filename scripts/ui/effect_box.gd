extends HBoxContainer

var Effects: Dictionary = {}

func add_effect(Effect):
	var effect_instance = GlobalVar.Effect_scene.instantiate()
	effect_instance.set_sprite(Effect)
	Effects[effect_instance] = effect_instance
	add_child(effect_instance)

func delete_effect(Effect):
	Effects[Effect].queue_free()
	Effects.erase(Effect)

func delete_all_effects():
	for effect in Effects.values():
		effect.queue_free()
	Effects.clear()