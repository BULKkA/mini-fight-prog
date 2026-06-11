extends BaseEnemy
class_name Golem

func _perform_attack() -> void:
	
	if global_position.distance_to(target.global_position) > attack_range:
		set_state(State.CHASE)
		return
	
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	await get_tree().create_timer(0.4).timeout
	_play_attack_animation(currentAttack.Name)


func _set_idle_dir_from_direction(direction: Vector2) -> void:
	if direction.x != 0:
		idle_dir = Direction.LEFT if direction.x < 0.0 else Direction.RIGHT

func _update_animation() -> void:
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		_set_animation(&"Idle")
		return
	animated_sprite.flip_h = idle_dir == Direction.LEFT
	_set_animation(&"Walk")

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

func _on_attack_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
