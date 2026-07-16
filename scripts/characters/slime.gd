extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

const SPEED: float = 150.0
# The characters are scaled in game.tscn, so this range must clear their
# world-space collision shapes before the slime can begin its swing.
const ATTACK_RANGE: float = 60.0
const ATTACK_DAMAGE: int = 15
const ATTACK_WINDUP: float = 0.45
const ATTACK_DURATION: float = 0.9
const ATTACK_COOLDOWN: float = 0.65
const KNOCKBACK_FORCE: float = 100.0

var is_alive: bool = true
var target: Node2D
var last_direction := Vector2.RIGHT
var health: int = 100
var state: State = State.IDLE
var attack_time: float = 0.0
var cooldown_time: float = 0.0
var has_dealt_damage: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar


func _physics_process(delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		return

	cooldown_time = maxf(cooldown_time - delta, 0.0)
	if not is_instance_valid(target):
		target = null

	if state == State.ATTACK:
		_process_attack(delta)
	elif target == null:
		_set_state(State.IDLE)
	else:
		_process_target()

	move_and_slide()


func _process_target() -> void:
	var direction := global_position.direction_to(target.global_position)
	var distance := global_position.distance_to(target.global_position)
	if direction != Vector2.ZERO:
		last_direction = direction

	if distance <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		if cooldown_time <= 0.0:
			_start_attack()
		else:
			_set_state(State.IDLE)
	else:
		velocity = direction * SPEED
		_set_state(State.MOVE)
		play_animation("move", last_direction)


func _start_attack() -> void:
	attack_time = 0.0
	has_dealt_damage = false
	_set_state(State.ATTACK)


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	attack_time += delta

	if not has_dealt_damage and attack_time >= ATTACK_WINDUP:
		has_dealt_damage = true
		if is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= ATTACK_RANGE + 8.0 \
			and target.has_method("take_damage"):
			target.take_damage(ATTACK_DAMAGE, global_position)

	if attack_time >= ATTACK_DURATION:
		cooldown_time = ATTACK_COOLDOWN
		_set_state(State.IDLE)


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			play_animation("idle", last_direction)
		State.MOVE:
			play_animation("move", last_direction)
		State.ATTACK:
			play_animation("attack", last_direction)


func play_animation(prefix: String, direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite_2d.flip_h = direction.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif direction.y < 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_up")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_down")


func take_damage(damage: int, attacker_position: Vector2) -> void:
	if not is_alive:
		return

	health = maxi(health - damage, 0)
	health_bar.update_health(health)
	take_damage_sound.play()
	if health <= 0:
		_die()
	else:
		var knockback_direction := attacker_position.direction_to(global_position)
		var target_position := position + knockback_direction * KNOCKBACK_FORCE
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_position, 0.5)


func _die() -> void:
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO
	target = null
	animated_sprite_2d.play("dead")
	await animated_sprite_2d.animation_finished
	queue_free()


func _on_sight_area_shape_entered(
	_area_rid: RID,
	area: Area2D,
	_area_shape_index: int,
	_local_shape_index: int
) -> void:
	if area.name == "Body":
		target = area.get_parent()


func _on_sight_area_shape_exited(
	_area_rid: RID,
	area: Area2D,
	_area_shape_index: int,
	_local_shape_index: int
) -> void:
	if area.name == "Body" and area.get_parent() == target:
		target = null
		velocity = Vector2.ZERO
		if state != State.ATTACK:
			_set_state(State.IDLE)
