extends Node


func copy_properties(from_obj, to_obj, properties):
	for prop in properties:
		to_obj.set(prop, from_obj.get(prop))

func copy_all_properties(data, obj):
	var props = {}
	for p in obj.get_property_list():
		props[p.name] = true
	for key in data:
		if key in props:
			obj.set(key, data[key])


func combine_effects(Effect1, Effect2):
	if Effect1 == GlobalVar.Effect.NONE:
		return Effect2
	if Effect2 == GlobalVar.Effect.NONE:
		return Effect1
	var key = GlobalVar.Effect.keys()[Effect1] + "+" + GlobalVar.Effect.keys()[Effect2]
	if key in GlobalVar.Effect_connect:
		return GlobalVar.Effect[GlobalVar.Effect_connect[key]]
	return GlobalVar.Effect.NONE