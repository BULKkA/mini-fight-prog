extends CharacterBody2D
class_name BaseEnemy

enum State {
	CHASE,		
	ATTACK
}
enum Direction{
	UP,
	UP_LEFT,
	UP_RIGHT,
	DOWN,
	DOWN_LEFT,
	DOWN_RIGHT,
	LEFT,
	RIGHT
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
var target = GlobalVar.Player
var current_health: int: 
	set(value):
		current_health = value
		HealthBar.update_hearts(current_health)

var knockback_velocity: Vector2 = Vector2.ZERO
var movement_velocity: Vector2 = Vector2.ZERO	# только AI-движение, без knockback
var is_attacking := false
var idle_dir: Direction = Direction.RIGHT
var is_alive: bool = true
var stun: bool  = false
var currentAttack
var can_be_stunned: bool = true
var current_combined_effect = null
var CurrentEffects: Dictionary = {}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var HealthBar: TextureProgressBar = $HealthBar
@onready var EffectBar: VBoxContainer = $EffectBar

func Init_Enemy(EnemyData):
	GlobalFunc.copy_all_properties(EnemyData, self)

func _ready() -> void:
	HealthBar.create_hearts(max_health)
	current_health = max_health

	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = attack_range
	navigation_agent.avoidance_enabled = false

	_On_Ready()

func _physics_process(delta: float) -> void:
	if not is_alive or is_attacking or stun:
		return

	match state:
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack(delta)

	update_knockback(delta)
	velocity = movement_velocity + knockback_velocity
	move_and_slide()
	_set_idle_dir_from_direction(velocity)
	_update_animation()

func update_knockback(delta: float) -> void:
	if knockback_velocity == Vector2.ZERO:
		return

	var safe_heaviness: float = max(0.001, heaviness)
	var decel: float = (KNOCKBACK_DECAY / safe_heaviness) * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, decel)

	if knockback_velocity.length_squared() <= 0.00001:
		knockback_velocity = Vector2.ZERO

func _update_animation() -> void:
	if movement_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		_set_animation(&"Idle_" + Direction.keys()[idle_dir])
		return

	_set_animation(&"Walk_" + Direction.keys()[idle_dir])

func _set_idle_dir_from_direction(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		idle_dir = Direction.LEFT if direction.x < 0 else Direction.RIGHT
	else:
		idle_dir = Direction.UP if direction.y < 0 else Direction.DOWN
	

func _chase(delta: float) -> void:
	if not target:
		return
		
	navigation_agent.target_position = target.global_position

	var next_point: Vector2 = navigation_agent.get_next_path_position()
	var to_next: Vector2 = next_point - global_position

	if to_next.length_squared() > MIN_MOVE_SPEED_SQ:
		var dir: Vector2 = to_next.normalized()
		movement_velocity = dir * speed
	else:
		movement_velocity = Vector2.ZERO

	if global_position.distance_to(target.global_position) <= attack_range:
		set_state(State.ATTACK)
	
	if randf() < 0.05:
		movement_velocity = Vector2.ZERO
		return
	
func _attack(delta: float) -> void:
	movement_velocity = Vector2.ZERO
	if not is_attacking:
		is_attacking = true
		await _perform_attack()
		is_attacking = false

func set_state(new_state: State) -> void:
	if new_state == state:
		return

	_on_state_exit(state)
	state = new_state
	_on_state_enter(state)

func take_hit(amount: int, knockback: Dictionary = {}, Effect = GlobalVar.Effect.NONE) -> void: 
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
	
	Take_Effect(Effect)
	
	if current_health <= 0:
		die()
	elif can_be_stunned:
		stun = true
		_set_animation("Hurt")
		await animated_sprite.animation_finished
		stun = false

func Take_Effect(Effect):
	if Effect == GlobalVar.Effect.NONE or current_combined_effect != null:
		return
	
	var effect_data = GlobalVar.effect_data[Effect]
	var find_effect = CurrentEffects.find(Effect)

	if find_effect != -1 :
		CurrentEffects[Effect].Duration = effect_data.Duration
		return

	EffectBar.add_effect(Effect)
	CurrentEffects[Effect] = effect_data

	_on_take_effect(effect_data)

	if CurrentEffects.size() > 1:
		effect_connection(CurrentEffects)

	await effect_process(Effect, effect_data)
	
	EffectBar.delete_effect(Effect)
	CurrentEffects.erase(Effect)

func effect_process(Effect, effect_data):
	var elapsed := 0.0
	speed *= (1.0 - effect_data.SlowPercent)
	while CurrentEffects.has(Effect):
		if effect_data.DamagePerTick > 0:
			take_hit(effect_data.DamagePerTick, {}, GlobalVar.Effect.NONE)
		await get_tree().create_timer(effect_data.TickTime).timeout
		
		CurrentEffects[Effect].Duration -= effect_data.TickTime

		if CurrentEffects[Effect].Duration <= 0:
			break

	speed /= (1.0 - effect_data.SlowPercent)

func effect_connection(CurrentEffects)
	current_combined_effect = GlobalFunc.combine_effects(CurrentEffects[0], CurrentEffects[1])
	effect_data = GlobalVar.Effect_connect_data[current_combined_effect]
	CurrentEffects[current_combined_effect] = effect_data
	if effect_data:
		await effect_process(current_combined_effect, effect_data)
		current_combined_effect = null
		CurrentEffects.erase(current_combined_effect)


func die() -> void:
	is_alive = false 
	_on_die()
	_set_animation("Die")
	await animated_sprite.animation_finished
	clothCollisions()
	await get_tree().create_timer(3).timeout
	queue_free()

func attackBody(body):
	var direction = (body.global_position - global_position).normalized()
	var knockback := {
		"direction": direction,
		"strength": currentAttack.Strength
	}
	body.take_hit(currentAttack.Damage, knockback, GlobalVar.Effect[currentAttack.Effect])

func get_current_health():
	return current_health

func clothCollisions():
	for child in get_children():
		if child is Area2D:
			child.monitorable = false





func _On_Ready() -> void:
	pass

func _on_die():
	pass

func _on_take_damage(amount: int) -> void:
	pass

func _on_take_effect(Effect) -> void:
	pass

func _on_state_enter(new_state: State) -> void:
	pass

func _on_state_exit(old_state: State) -> void:
	pass

func _perform_attack() -> void:
	pass


func _set_animation(animation_name: StringName) -> void:
	if animated_sprite.animation == animation_name:
		return
	animated_sprite.play(animation_name)
