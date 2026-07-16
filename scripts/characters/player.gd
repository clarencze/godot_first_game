extends CharacterBody2D

const SPEED: float = 300.0
const MAX_HEALTH: int = 100
const DAMAGE_INVULNERABILITY: float = 0.5

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var strength: int = 20
var health: int = MAX_HEALTH
var is_alive: bool = true
var invulnerability_time: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sword: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $Hitbox
@onready var body: Area2D = $Body
@onready var health_bar: Node2D = $HealthBar


func _ready() -> void:
	hitbox_offset = hitbox.position
	hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	invulnerability_time = maxf(invulnerability_time - delta, 0.0)
	if not is_alive:
		velocity = Vector2.ZERO
		return

	process_movement()

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	process_animation()
	move_and_slide()


func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:
		velocity = direction * SPEED

		# Keep the active attack facing the direction it started in.
		if not is_attacking:
			last_direction = direction
			update_hitbox_offset()
	else:
		velocity = Vector2.ZERO


func process_animation() -> void:
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)


func play_animation(prefix: String, direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite_2d.flip_h = direction.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif direction.y < 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_up")
	elif direction.y > 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_down")


func attack() -> void:
	if not is_alive:
		return

	is_attacking = true
	update_hitbox_offset()
	hitbox.monitoring = true
	swing_sword.play()
	play_animation("attack", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y

	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x < 0:
			hitbox.position = Vector2(-x, y)
		else:
			hitbox.position = Vector2(x, y)
	else:
		if last_direction.y < 0:
			hitbox.position = Vector2(y, -x)
		else:
			hitbox.position = Vector2(-y, x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(strength, global_position)


func take_damage(damage: int, _attacker_position: Vector2) -> void:
	if not is_alive or invulnerability_time > 0.0:
		return

	health = maxi(health - damage, 0)
	health_bar.update_health(health)
	invulnerability_time = DAMAGE_INVULNERABILITY
	if health <= 0:
		_die()


func _die() -> void:
	is_alive = false
	is_attacking = false
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	body.monitorable = false
	animated_sprite_2d.play("dead")
