extends CharacterBody2D

const SPEED: int = 150

var target: Node2D = null
var last_direction: Vector2 = Vector2.RIGHT
var health: int = 100
var KNOCKBACK_FORCE: int = 100

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage

func _physics_process(_delta: float) -> void:
	if target:
		attack_target()
	else:
		velocity = Vector2.ZERO

	process_animation()
	move_and_slide()


func attack_target() -> void:
	var direction := global_position.direction_to(target.global_position)

	velocity = direction * SPEED
	last_direction = direction


func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("attack", last_direction)
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


func take_damage(damage: int, attacker_posistion: Vector2) -> void:
	health -= damage
	print("Slime health: ", health)
	take_damage_sound.play()
	
	var knockback_direction = (position - attacker_posistion).normalized()
	var target_position = position + knockback_direction * KNOCKBACK_FORCE
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.5)
	if health <= 0:
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
	if area.name == "Body":
		target = null
		velocity = Vector2.ZERO
