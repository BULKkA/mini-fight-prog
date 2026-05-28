extends BaseEnemy
  
func _ready() -> void:

	spawn_position = global_position
	HealthBar.create_hearts(max_health)
	current_health = max_health

	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = attack_range
	navigation_agent.avoidance_enabled = false


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	move_and_slide()
	_update_knockback(delta)
	if is_attacking or stun:
		return
		
	match state:
		State.IDLE:
			_idle(delta)
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)
		State.RETURN:
			_return(delta)
			
	velocity = movement_velocity + knockback_velocity
	_set_facing_dir_from_direction(velocity)
	_update_animation()

func _chase(delta: float) -> void:
	if target:
		navigation_agent.target_position 
		var next_point: Vector2 = navigation_agent.get_next_path_position()
		var to_next: Vector2 = next_point - global_position
		if to_next.length_squared() > MIN_MOVE_SPEED_SQ:
			var dir: Vector2 = to_next.normalized()
			movement_velocity = dir * speed
			_update_facing_from_direction(dir)
		else:
			movement_velocity = Vector2.ZERO
		set_state(State.ATTACK)

func _attack(delta: float) -> void:
	movement_velocity = Vector2.ZERO
	if not is_attacking:
		is_attacking = true
		currentAttack = attacks.Attack_Light if randi_range(0,  100) > 15 else attacks.Attack_Hight
		_perform_attack(currentAttack)

func _perform_attack(AttackType) -> void:
	
	is_attacking = true
	_sync_attack_box_to_facing_dir(AttackType)
	
	await get_tree().create_timer(0.4).timeout
	
	_play_attack_animation(AttackType.anim)
	
	await get_tree().create_timer(AttackType.hitbox_start).timeout
	AttackType.area.monitoring = true
	await get_tree().create_timer(AttackType.hitbox_end).timeout
	AttackType.area.monitoring = false
	is_attacking = false
	
	await get_tree().create_timer(0.5).timeout
	
	if target:
		set_state(State.CHASE)
	else:
		set_state(State.RETURN)
