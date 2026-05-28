extends Node


func copy_properties(from_obj, to_obj, properties):
	for prop in properties:
		to_obj.set(prop, from_obj.get(prop))

func copy_all_properties(from_obj, to_obj):
	for prop in from_obj.get_property_list():
		var name = prop.name
		if to_obj.get(name) != null:
			to_obj.set(name, from_obj.get(name))
