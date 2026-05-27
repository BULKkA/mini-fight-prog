extends CharacterBody2D
class_name BaseEnemy

enum State {
	IDLE,		# стоит на месте
	CHASE,		# преследует цель
	ATTACK,		# выполняет атаку (реализуется в наследниках)
	RETURN		# возвращается к точке спавна
}

var attacks = {}

@export var speed := 80.0
@export var max_health := 2
@export var heaviness: float = 1.0
@export var attack_range: float = 24.0

@onready var visibility_area: Area2D = $VisibilityArea
@onready var body_area: Area2D = $BodyArea
@onready var exit_area: Area2D = $ExitArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var Attack_LightArea = $Attack_Light
@onready var Attack_HightArea = $Attack_Hight
@onready var HealthBar: TextureProgressBar = $HealthBar

const MIN_MOVE_SPEED_SQ := 0.0001
const KNOCKBACK_DECAY := 2000.0

var state: State = State.IDLE
var target: Node2D = null
var spawn_position: Vector2
var current_health: int: 
	set(value):
		current_health = value
		HealthBar.update_hearts(current_health)

var knockback_velocity: Vector2 = Vector2.ZERO
var movement_velocity: Vector2 = Vector2.ZERO	# только AI-движение, без knockback
var is_attacking := false
var facing_dir: Vector2 = Vector2.RIGHT
var is_alive: bool = true
var stun: bool  = false
var currentAttack

func _ready() -> void:
	attacks = {
		"Attack_Light": {
		"anim": "Attack_Light",
		"area": Attack_LightArea,
		"duration": 1,
		"hitbox_start": 0.55,
		"hitbox_end": 0.25,
		"damage": 1
		},
		"Attack_Hight": {
			"anim": "Attack_Hight",
			"area": Attack_HightArea,
			"duration": 2,
			"hitbox_start": 1,
			"hitbox_end": 0.25,
			"damage": 2
		}
	}
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
	

func _update_knockback(delta: float) -> void:
	if knockback_velocity == Vector2.ZERO:
		return

	var safe_heaviness: float = max(0.001, heaviness)
	var decel: float = (KNOCKBACK_DECAY / safe_heaviness) * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, decel)

	if knockback_velocity.length_squared() <= 0.00001:
		knockback_velocity = Vector2.ZERO

func _update_animation() -> void:
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		_set_animation(&"Idle")
		return

	facing_dir = Vector2.LEFT if movement_velocity.x < 0.0 else Vector2.RIGHT
	animated_sprite.flip_h = facing_dir == Vector2.LEFT
	_set_animation(&"Walk")

func _set_animation(animation_name: StringName) -> void:
	if animated_sprite.animation == animation_name:
		return
	animated_sprite.flip_h = facing_dir == Vector2.LEFT
	animated_sprite.play(animation_name)

func _set_facing_dir_from_direction(direction: Vector2) -> void:
	if direction.x != 0:
		facing_dir = Vector2.LEFT if direction.x < 0.0 else Vector2.RIGHT

func _sync_attack_box_to_facing_dir(AttackType) -> void:
	AttackType.area.scale.x = -1 if facing_dir == Vector2.LEFT else 1

func _idle(delta: float) -> void:
	movement_velocity = Vector2.ZERO

func _chase(delta: float) -> void:
	if target:
		navigation_agent.target_position = target.global_position

		var next_point: Vector2 = navigation_agent.get_next_path_position()
		var to_next: Vector2 = next_point - global_position

		if to_next.length_squared() > MIN_MOVE_SPEED_SQ:
			var dir: Vector2 = to_next.normalized()
			movement_velocity = dir * speed
			_update_facing_from_direction(dir)
		else:
			movement_velocity = Vector2.ZERO

		if global_position.distance_to(target.global_position) <= attack_range:
			set_state(State.ATTACK)
	else:
		movement_velocity = Vector2.ZERO

func _attack(delta: float) -> void:
	movement_velocity = Vector2.ZERO
	if not is_attacking:
		is_attacking = true
		currentAttack = attacks.Attack_Light if randi_range(0,  100) > 15 else attacks.Attack_Hight
		_perform_attack(currentAttack)

func _return(delta: float) -> void:
	navigation_agent.target_position = spawn_position

	var next_point: Vector2 = navigation_agent.get_next_path_position()
	var to_next: Vector2 = next_point - global_position

	if global_position.distance_to(spawn_position) < 5.0:
		set_state(State.IDLE)
		movement_velocity = Vector2.ZERO
		return

	if to_next.length_squared() > MIN_MOVE_SPEED_SQ:
		var normalized_dir: Vector2 = to_next.normalized()
		movement_velocity = normalized_dir * speed
		_update_facing_from_direction(normalized_dir)
	else:
		movement_velocity = Vector2.ZERO

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

func _update_facing_from_direction(dir: Vector2) -> void:
	facing_dir = Vector2.LEFT if dir.x < 0.0 else Vector2.RIGHT

func _play_attack_animation(AttackType) -> void:
	if not is_alive:
		return
	if movement_velocity.x < 0:
		animated_sprite.flip_h = true
		_set_animation(AttackType)
	else:
		animated_sprite.flip_h = false
		_set_animation(AttackType)

func set_state(new_state: State) -> void:
	if new_state == state:
		return

	_on_state_exit(state)
	state = new_state
	_on_state_enter(state)

func _on_state_enter(new_state: State) -> void:
	pass

func _on_state_exit(old_state: State) -> void:
	pass

func take_hit(amount: int, knockback: Dictionary = {}) -> void: 
	if not is_alive:
		return
		
	current_health -= amount
	_on_take_damage(amount)

	if knockback.size() > 0 and knockback.has("direction") and knockback.has("strength"):
		var dir: Vector2 = knockback.get("direction", Vector2.ZERO)
		var strength: float = float(knockback.get("strength", 0.0))
		var safe_heaviness: float = max(0.001, heaviness)

		if dir != Vector2.ZERO and strength > 0.0:
			knockback_velocity += dir.normalized() * (strength / safe_heaviness)

	if current_health <= 0:
		die()
	else:
		stun = true
		_set_animation("Hurt")
		await animated_sprite.animation_finished
		stun = false

func _on_take_damage(amount: int) -> void:
	pass

func die() -> void:
	is_alive = false 
	_set_animation("Die")
	await animated_sprite.animation_finished
	clothCollisions()
	

func _on_visibility_area_area_entered(area: Area2D) -> void:
	target = area.get_parent() if area.get_parent() is Node2D else area
	if state != State.ATTACK:
		set_state(State.CHASE)

func _on_body_area_area_entered(area: Area2D) -> void:
	if area == target or area.get_parent() == target:
		movement_velocity = Vector2.ZERO
		set_state(State.ATTACK)

func _on_body_area_area_exited(area: Area2D) -> void:
	if area == target or area.get_parent() == target:
		set_state(State.CHASE)

func _on_exit_area_area_exited(area: Area2D) -> void:
	if area == target or area.get_parent() == target:
		target = null
		set_state(State.RETURN)

func _on_attack_light_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func _on_attack_hight_area_entered(area: Area2D) -> void:
	attackBody(area.get_parent())

func attackBody(body):
	var dir := Vector2.ZERO
	match facing_dir:
		Vector2.LEFT:
			dir = Vector2(-1, 0)
		Vector2.RIGHT:
			dir = Vector2(1, 0)

	var knockback := {
		"direction": dir,
		"strength": 220.0
	}
	body.take_hit(currentAttack.damage, knockback)

func get_current_health():
	return current_health

func clothCollisions():
	for child in get_children():
		if child is Area2D:
			child.monitorable = false
