extends Control


func _on_start_pressed() -> void:
	LevelManager.start_level()

func _on_quit_pressed() -> void:
	get_tree().quit()
