extends TextureProgressBar

var max_health
var current_health

var hp_tween: Tween

func create_hearts(health):
	max_health = health
	max_value = max_health
	value = health

func update_hearts(health):
	current_health = clamp(health, 0, max_health)

	if hp_tween:
		hp_tween.kill()

	hp_tween = create_tween()

	hp_tween.tween_property(
		self,
		"value",
		current_health,
		0.2
	)
