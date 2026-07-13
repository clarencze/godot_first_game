extends Node2D

@onready var health_bar: Sprite2D = $Health
@onready var defaulth_width = health_bar.region_rect.size.x
@onready var defaulth_height = health_bar.region_rect.size.y

func update_health(new_health: int) -> void:
	var new_width = (new_health / 100.0) * defaulth_width
	health_bar.region_rect = Rect2(0, 0, new_width, defaulth_height)
