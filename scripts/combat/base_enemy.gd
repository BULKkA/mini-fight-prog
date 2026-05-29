extends CharacterBody2D
class_name BaseEnemy

enum State {
	CHASE,		
	ATTACK
}

const MIN_MOVE_SPEED_SQ := 0.0001
const KNOCKBACK_DECAY := 2000.0

var attacks
var spells
var speed := 80.0
var max_health := 2
var heaviness: float = 1.0
var attack_range: float = 24.0
var state: State = State.CHASE
var target: Node2D = GlobalVar.player
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
var can_be_stunned: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var HealthBar: TextureProgressBar = $HealthBar

func _ready() -> void:
	HealthBar.create_hearts(max_health)
	current_health = max_health

	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = attack_range
	navigation_agent.avoidance_enabled = false

	_On_Ready()

func _On_Ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	move_and_slide()
	_update_knockback(delta)
	if is_attacking or stun:
		return
		
	match state:
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)
			
	velocity = movement_velocity + knockback_velocity
	_set_facing_dir_from_direction(velocity)
	_update_animation()

func Init_Enemy(EnemyData):
	GlobalFunc.copy_all_properties(EnemyData, self)


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
		await _perform_attack()
		is_attacking = false

func _perform_attack():
	return true

func _update_facing_from_direction(dir: Vector2) -> void:
	facing_dir = Vector2.LEFT if dir.x < 0.0 else Vector2.RIGHT

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
	elif can_be_stunned:
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
