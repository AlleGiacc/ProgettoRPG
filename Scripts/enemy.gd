extends CharacterBody2D

var speed = 70
var player_chase = false
var player = null
var status = "patrol"
var starting_position = Vector2.ZERO
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_polygon_2d = $DetectionArea/CollisionPolygon2D
@onready var pathfollow = get_parent()
var direction = 1
var movement_velocity = Vector2.ZERO
@onready var timer = $Timer


func _ready():
	starting_position = position  # Imposta la posizione iniziale quando la scena viene avviata

func _physics_process(delta):
	match status:
		"chase":
			chase_player(delta)
		"patrol":
			patrol_path(delta)
		"return":
			return_to_starting_position(delta)
	
	velocity = movement_velocity
	move_and_slide()

func chase_player(delta):
	if player:
		collision_polygon_2d.look_at(player.position)
		var direction = (player.global_position - global_position).normalized()
		movement_velocity = direction * speed
		if direction.x < 0:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false

func patrol_path(delta):
	animated_sprite_2d.play("walk")
	if direction == 1:
		if pathfollow.progress_ratio == 1:
			animated_sprite_2d.flip_h = true
			collision_polygon_2d.rotation_degrees = 180
			direction = 0
		else:
			pathfollow.progress += speed * delta
	else:
		if pathfollow.progress_ratio == 0:
			animated_sprite_2d.flip_h = false
			collision_polygon_2d.rotation_degrees = 0
			direction = 1
		else:
			pathfollow.progress -= speed * delta
	movement_velocity = Vector2.ZERO

func return_to_starting_position(delta):
	var direction = (starting_position - position).normalized()
	movement_velocity = direction * speed
	if position.distance_to(starting_position) < 1:
		position = starting_position
		status = "patrol"
	if (starting_position.x - position.x) < 0:
		animated_sprite_2d.flip_h = true
		collision_polygon_2d.rotation_degrees = 180
	else:
		animated_sprite_2d.flip_h = false
		collision_polygon_2d.rotation_degrees = 0

func _on_detection_area_body_entered(body):
	if body is Player:
		player = body
		status = "chase"
		animated_sprite_2d.play("walk")
		print("Inseguimento")

func _on_detection_area_body_exited(body):
	if body is Player:
		player = null
		timer.start()
		print("Ritorno")
