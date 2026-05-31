extends BaseEnemy

func _perform_attack() -> void:
	
	if global_position.distance_to(target.global_position) > attack_range:
		set_state(State.CHASE)
		return
	
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	_sync_attack_box_to_facing_dir(currentAttack)
	
	await get_tree().create_timer(0.4).timeout
	_play_attack_animation(currentAttack.Name)
	await get_tree().create_timer(0.5).timeout


func _play_attack_animation(AttackType) -> void:
	if not is_alive:
		return
	AnimPlayer.play(AttackType)
	if movement_velocity.x < 0:
		animated_sprite.flip_h = true
		_set_animation(AttackType)
	else:
		animated_sprite.flip_h = false
		_set_animation(AttackType)

func _sync_attack_box_to_facing_dir(AttackType) -> void:
	get_node(AttackType.Name).scale.x = -1 if facing_dir == Vector2.LEFT else 1
	
func _on_attack_light_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func _on_attack_hight_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
