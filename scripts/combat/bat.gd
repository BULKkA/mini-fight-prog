extends BaseEnemy

var dash_velocity: Vector2 = Vector2.ZERO

func _on_physics_process(delta):
	if is_attacking and dash_velocity != Vector2.ZERO:
		velocity = dash_velocity
		move_and_slide()
		# тормозим после дэша
		dash_velocity = dash_velocity.move_toward(Vector2.ZERO, 4000.0 * delta) #ИИ Слоп

func _on_state_enter(new_state: State):
	if new_state == State.CHASE:
		movement_velocity = Vector2.ZERO
		animated_sprite.play("Idle")

func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		set_state(State.CHASE)
		return
	
	currentAttack = attacks[0]
	
	# Дэш-рывок к цели
	var dir = (target.global_position - global_position).normalized()
	dash_velocity = dir * (speed * 3.0)  # х3 от обычной скорости
	AnimPlayer.play(currentAttack.Name)
	_set_animation(currentAttack.Name)
	await animated_sprite.animation_finished
	
	dash_velocity = Vector2.ZERO
	
	await get_tree().create_timer(0.2).timeout

	is_attacking = false
	set_state(State.CHASE)

func _set_idle_dir_from_direction(direction: Vector2) -> void:
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0

func _update_animation() -> void:
	if not is_alive or is_attacking:
		return
	animated_sprite.flip_h = movement_velocity.x > 0
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		if animated_sprite.animation != &"Idle":
			animated_sprite.play("Idle")
		return
	if animated_sprite.animation != &"Walk":
		animated_sprite.play("Walk")

func _on_attack_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	attackBody(body)
