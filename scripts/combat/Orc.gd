extends BaseEnemy

func _perform_attack() -> void:
	
	var dir = (target.global_position - global_position).normalized()
	_set_idle_dir_from_direction(dir)
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	_sync_attack_box_to_facing_dir(currentAttack)
	AnimPlayer.play(currentAttack.Name)
	_set_animation(currentAttack.Name)
	await animated_sprite.animation_finished
	is_attacking = false
	set_state(State.CHASE)

func _set_idle_dir_from_direction(direction: Vector2) -> void:
	if direction.x != 0:
		idle_dir = Direction.LEFT if direction.x < 0.0 else Direction.RIGHT

func _update_animation() -> void:
	if is_attacking:
		return
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		_set_animation(&"Idle")
		return
	animated_sprite.flip_h = idle_dir == Direction.LEFT
	_set_animation(&"Walk")

func _sync_attack_box_to_facing_dir(AttackType) -> void:
	get_node(AttackType.Name).scale.x = -1 if idle_dir == Direction.LEFT else 1
	
func _on_attack_light_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func _on_attack_hight_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
