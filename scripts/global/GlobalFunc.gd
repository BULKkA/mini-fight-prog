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
