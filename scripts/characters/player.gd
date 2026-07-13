extends CharacterBody2D

const SPEED: float = 300.0

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var strength: int = 20

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sword: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	hitbox_offset = hitbox.position
	hitbox.monitoring = false


func _physics_process(_delta: float) -> void:
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
	print("Hitbox touched: ", body.name)

	if is_attacking and body.has_method("take_damage"):
		body.take_damage(strength, position)
