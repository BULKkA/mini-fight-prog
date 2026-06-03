extends BaseEnemy

func _perform_attack() -> void:
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	await get_tree().create_timer(0.4).timeout
	_set_animation("Attack_" + Direction.keys()[idle_dir])
	AnimPlayer.play("Attack_" + Direction.keys()[idle_dir])
	await AnimPlayer.animation_finished
	set_state(State.CHASE)
	return


func _on_area_2d_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
