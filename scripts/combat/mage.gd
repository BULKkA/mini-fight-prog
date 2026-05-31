extends BaseEnemy

var is_Casting = false
@onready var Casts: AnimatedSprite2D = $Casts

func _chase(delta: float) -> void:
	if not target:
		target = GlobalVar.Player
	var roll := randi_range(0, 100)
	if roll < 10:
		movement_velocity = Vector2.ZERO
		set_state(State.ATTACK)
		return
	if roll > 90:
		Use_Spell(spells[randi_range(0, spells.size() - 1)])
		set_state(State.ATTACK)
		return
	if navigation_agent.is_navigation_finished():
		var offset := Vector2(
			randf_range(-120, 120),
			randf_range(-120, 120)
		)
		navigation_agent.target_position = self.global_position + offset
	var next_point: Vector2 = navigation_agent.get_next_path_position()
	var dir: Vector2 = (next_point - global_position).normalized()
	if randf() < 0.05:
		movement_velocity = Vector2.ZERO
		return
	movement_velocity = dir * speed
	_update_facing_from_direction(dir)

func _perform_attack() -> void:
	if Casts.visible:
		return
	await get_tree().create_timer(0.4).timeout
	currentAttack = attacks[randi_range(0,  attacks.size() - 1)]
	Casts.visible = true
	Casts.play(currentAttack.Name)
	await Casts.animation_finished
	Casts.visible = false
	SpawnMagic(load(currentAttack.Body).instantiate())
	set_state(State.CHASE)

func Use_Spell(Spell):
	Casts.visible = true
	Casts.play(Spell.Name)
	if Spell.Name == "Teleport":
		AnimPlayer.play("Teleport")
		await  AnimPlayer.animation_finished
		Teleport()
	await Casts.animation_finished 
	Casts.visible = false
	set_state(State.CHASE)

func Teleport():
	var nav_map := get_world_2d().navigation_map
	for i in range(10):
		var offset := Vector2(
			randf_range(-150, 150),
			randf_range(-150, 150)
		)
		var pos := self.global_position + offset
		var closest_point := NavigationServer2D.map_get_closest_point(nav_map, pos)
		if closest_point.distance_to(pos) > 20:
			continue
		navigation_agent.target_position = closest_point
		if navigation_agent.is_target_reachable():
			global_position = closest_point
			navigation_agent.velocity = Vector2.ZERO
			return

func SpawnMagic(Magic):
	Magic.global_position = target.global_position
	GlobalFunc.copy_all_properties(currentAttack, Magic)
	get_tree().current_scene.add_child(Magic)

func _on_die():
	Casts.stop()
	Casts.visible = false
	
