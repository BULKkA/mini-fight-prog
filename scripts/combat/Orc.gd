extends BaseEnemy
class_name Orc

func _On_Ready() -> void:
	var EnemyData = GlobalVar.Enemies["Orc"]
	Init_Enemy(EnemyData)

func _perform_attack():
	
	var AttackType = attacks.Attack_Light if randi_range(0,  100) > 15 else attacks.Attack_Hight
	_sync_attack_box_to_facing_dir(AttackType)
	
	await get_tree().create_timer(0.4).timeout
	
	_play_attack_animation(AttackType.anim)
	
	await get_tree().create_timer(AttackType.hitbox_start).timeout
	AttackType.area.monitoring = true
	await get_tree().create_timer(AttackType.hitbox_end).timeout
	AttackType.area.monitoring = false
	
	await get_tree().create_timer(0.5).timeout
	
	return true

func _play_attack_animation(AttackType) -> void:
	if not is_alive:
		return
	if movement_velocity.x < 0:
		animated_sprite.flip_h = true
		_set_animation(AttackType)
	else:
		animated_sprite.flip_h = false
		_set_animation(AttackType)

func _sync_attack_box_to_facing_dir(AttackType) -> void:
	AttackType.area.scale.x = -1 if facing_dir == Vector2.LEFT else 1
	
func _on_attack_light_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func _on_attack_hight_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())
