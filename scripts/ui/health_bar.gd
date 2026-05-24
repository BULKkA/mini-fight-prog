extends HBoxContainer

@export var heart_scene: PackedScene
var hearts = []

# Called when the node enters the scene tree for the first time.
func create_hearts(current_health):
	for i in range(current_health):
		var heart = heart_scene.instantiate()
		add_child(heart)
		hearts.append(heart)
	update_hearts(current_health)

func update_hearts(current_health):
	var current_hearts = self.get_child_count()
	var deleteCount = current_hearts - current_health 
	for i in deleteCount:
		var heart = self.get_child(current_hearts - (i + 1))
		heart.queue_free()
