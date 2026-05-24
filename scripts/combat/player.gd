extends CharacterBody2D


const MIN_MOVE_SPEED_SQ := 0.0001

const KNOCKBACK_FORCE := 360.0			# базовая сила отбрасывания от каждой атаки
const KNOCKBACK_DECAY := 900.0			# насколько быстро гаснет скорость отбрасывания

@onready var PlayerAnim: AnimatedSprite2D = $PlayerAnim
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var HealthBar = $HealthBar 
@export var heaviness: float = 3.0
@export var SPEED := 100.0
@export var DASH_SPEED := 200.0
@export var DASH_COOLDOWN := 2

var knockback_velocity: Vector2 = Vector2.ZERO

enum Direction{
	UP,
	UP_LEFT,
	UP_RIGHT,
	DOWN,
	DOWN_LEFT,
	DOWN_RIGHT
}

var Max_Helth = 3
var current_health: int: 
	set(value):
		current_health = value
		HealthBar.update_hearts(current_health)
var is_dead := false

var speed := SPEED
var input_velocity: Vector2 = Vector2.ZERO	# только обычное управление, без knockback
var idle_dir := Direction.DOWN
var is_attacking := false
var is_dashing := false
var dash_is_cooldown := false
var dash_velocity: Vector2 = Vector2.DOWN
#var stun := false 

func _ready():
	HealthBar.create_hearts(Max_Helth)
	current_health = Max_Helth

func _physics_process(delta: float) -> void:
	
	if get_tree().paused or is_dead: #or stun:
		return
	_update_knockback(delta)
	
	if is_dashing:
		input_velocity = dash_velocity 
		velocity = input_velocity * DASH_SPEED
		move_and_slide()
		return
	
	input_velocity = Vector2.ZERO
	input_velocity.x = Input.get_axis("ui_left", "ui_right")
	input_velocity.y = Input.get_axis("ui_up", "ui_down")
	input_velocity = input_velocity.normalized()

	# Движение
	if input_velocity != Vector2.ZERO:
		dash_velocity = input_velocity 
		input_velocity *= SPEED
		_set_idle_dir_from_direction(input_velocity)
	velocity = input_velocity
	_update_animation()
	if Input.is_action_pressed("Attack"):
		attack()
	elif Input.is_action_pressed("Dash") and not dash_is_cooldown: 
		dash() 
	move_and_slide()

func dash() -> void:
	is_dashing = true
	_set_animation(PlayerAnim, "Dash_" + Direction.keys()[idle_dir])
	await PlayerAnim.animation_finished
	is_dashing = false
	
	dash_is_cooldown = true
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	dash_is_cooldown = false
	
func attack() -> void:
	# Защита от повторного старта атаки во время кулдауна/анимации
	if not is_attacking:
		return
	is_attacking = true
	#Анимации атаки тута
	AnimPlayer.play("Attack")
	await PlayerAnim.animation_finished
	is_attacking = false

func _update_knockback(delta: float) -> void:
	# Затухание отбрасывания
	if knockback_velocity == Vector2.ZERO:
		return

	var safe_heaviness: float = max(0.001, heaviness)
	var decel: float = (KNOCKBACK_DECAY / safe_heaviness) * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, decel)

	if knockback_velocity.length_squared() <= 0.00001:
		knockback_velocity = Vector2.ZERO

func _update_animation() -> void:
	if is_attacking:
		return
	if input_velocity.length_squared() <= MIN_MOVE_SPEED_SQ:
		_set_animation(PlayerAnim, "Idle_" + Direction.keys()[idle_dir])
	else:
		_set_animation(PlayerAnim, "Walk_" + Direction.keys()[idle_dir])

func _set_animation(animator, animation_name: StringName, physycAnim = null) -> void:
	# Чтобы не спамить play() одним и тем же клипом
	if animator.animation == animation_name:
		return
	animator.play(animation_name)
	if physycAnim != null:
		physycAnim.play(animation_name)

func _set_idle_dir_from_direction(direction: Vector2) -> void:
	# Диагонали
	if direction.x < 0 and direction.y < 0:
		idle_dir = Direction.UP_LEFT
	elif direction.x > 0 and direction.y < 0:
		idle_dir = Direction.UP_RIGHT
	elif (direction.x < 0 and direction.y > 0) or direction.x < 0:
		idle_dir = Direction.DOWN_LEFT
	elif (direction.x > 0 and direction.y > 0) or direction.x > 0:
		idle_dir = Direction.DOWN_RIGHT
	elif direction.y < 0:
		idle_dir = Direction.UP
	elif direction.y > 0:
		idle_dir = Direction.DOWN

func take_hit(amount: int, knockback: Dictionary = {}) -> void:
	# Основной вход для получения урона
	if is_dead or amount <= 0:
		return
		
	current_health -= amount
	if knockback.size() > 0 and knockback.has("direction") and knockback.has("strength"):
		var dir: Vector2 = knockback.get("direction", Vector2.ZERO)
		var strength: float = float(knockback.get("strength", 0.0))
		var safe_heaviness: float = max(0.001, heaviness)
		if dir != Vector2.ZERO and strength > 0.0:
			knockback_velocity += dir.normalized() * (strength / safe_heaviness)

	# Клампим и обновляем отображение здоровья (после каждого удара)
	if current_health < 0:
		current_health = 0

	# Смерть при исчерпании HP
	if current_health <= 0:
		die()
	
	# сделать эффекты получения уронаыв
	#stun = true
	#_set_animation(PlayerAnim, "Hurt") - 
	#await PlayerAnim.animation_finished
	#stun = false

func die() -> void:
	is_dead = true
	_set_animation(PlayerAnim, "Die_" + Direction.keys()[idle_dir])
	await PlayerAnim.animation_finished
