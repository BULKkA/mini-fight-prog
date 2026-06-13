extends BaseEnemy
class_name Golem

func _perform_attack() -> void:
	
	var dir = (target.global_position - global_position).normalized()
	_set_idle_dir_from_direction(dir)
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	
	AnimPlayer.play(currentAttack.Name)
	animated_sprite.flip_h = dir.x < 0
	_set_animation(currentAttack.Name)
	await  AnimPlayer.animation_finished
	
	is_attacking = false
	set_state(State.CHASE)

func _update_animation() -> void:
	animated_sprite.flip_h = idle_dir == Direction.LEFT
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		await get_tree().create_timer(0.5).timeout
		if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
			if is_attacking:
				return
			_set_animation(&"Idle")
			return
	_set_animation(&"Walk")
	

func _set_idle_dir_from_direction(direction: Vector2) -> void:
	if direction.x != 0:
		idle_dir = Direction.LEFT if direction.x < 0.0 else Direction.RIGHT


func _on_attack_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
