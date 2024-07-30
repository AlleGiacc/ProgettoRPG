extends CharacterBody2D

var body_to_chase
var speed = 70
var status = "patrol"
var direction = 1
var last_position
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision_polygon_2d = $DetectionArea/CollisionPolygon2D
@onready var pathfollow = get_parent() as PathFollow2D


func _ready():
	animated_sprite_2d.play("walk")
	last_position = global_position

func _physics_process(delta):
	match status:
		"patrol":
			patrol_path(delta)
		"chase":
			chasing(delta)
		"return":
			return_to_path(delta)
	print(status)
	move_and_slide()

func return_to_path(delta):
	var direction = (last_position - global_position).normalized()
	velocity = direction * speed
	if global_position.distance_to(last_position) < 1:
		global_position = last_position
		status = "patrol"
	if (last_position.x - global_position.x) < 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false
	update_collision_polygon()

func chasing(delta):
	update_collision_polygon()
	var direction = (body_to_chase.global_position - global_position).normalized()
	velocity = direction * speed
	if direction.x < 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false

func patrol_path(delta):
	velocity = Vector2.ZERO
	if direction == 1: # sto andando verso dx
		if pathfollow.progress_ratio >= 1: # devo girarmi verso sx
			direction = -1
			animated_sprite_2d.flip_h = true
		else: # devo far andare DX il nemico
			pathfollow.set_progress(pathfollow.get_progress() + speed * delta)
	else: # sto andando verso sx
		if pathfollow.progress_ratio <= 0: # devo girarmi verso dx
			direction = 1
			animated_sprite_2d.flip_h = false
		else: # devo far andare sx il nemico
			pathfollow.set_progress(pathfollow.get_progress() - speed * delta)
			
	update_collision_polygon()

func update_collision_polygon():
	if status == "patrol":
		var movement_direction = (global_position - last_position).normalized()
		collision_polygon_2d.look_at(global_position + movement_direction)
		last_position = global_position
	elif status == "chase":
		collision_polygon_2d.look_at(body_to_chase.global_position)
	elif status == "return":
		collision_polygon_2d.look_at(last_position)

func _on_detection_area_body_entered(body):
	if body is Player:
		status = "chase"
		body_to_chase = body
		print("inseguimento")

func _on_detection_area_body_exited(body):
	if body is Player:
		velocity = Vector2.ZERO
		status = "return"
		body_to_chase = null
		print("ritorno")


func _on_collision_area_body_entered(body):
	print("combattimento")
