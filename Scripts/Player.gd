extends CharacterBody2D
class_name Player

@onready var animated_sprite_2d = $AnimatedSprite2D

### VAR PER MOVIMENTO E SPRITE MOVIMENTO ### Volendo da cambiare con movimento smooth ma non per forza
const SPEED = 8000.0
var lastMovDirection = 0
var canMove = true

### VAR PER GESTIONE INTERAZIONI
@onready var all_interations = []
@onready var interact_label = $InteractionComponents/InteractLabel

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	var directionLR = Input.get_axis("LEFT", "RIGHT")
	var directionDU = Input.get_axis("UP", "DOWN")
	
	if canMove:
		if Input.is_action_just_pressed("ACTION"):
			execute_interaction()

		# Update velocity based on input
		update_velocity(delta, directionLR, directionDU)

		# Update animation based on direction
		update_animation(directionLR, directionDU)

		move_and_slide()

### FUNZIONI PER GESTIONE MOVIMENTO E SPRITE MOVIMENTO ############################################
func update_velocity(delta, directionLR, directionDU):
	if directionLR != 0:
		lastMovDirection = 0
		animated_sprite_2d.flip_h = directionLR == -1
		velocity.x = directionLR * SPEED * delta
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)

	if directionDU != 0:
		lastMovDirection = directionDU
		velocity.y = directionDU * SPEED * delta
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED * delta)

func update_animation(directionLR, directionDU):
	if directionLR != 0:
		animated_sprite_2d.play("RunLato")
	elif directionDU != 0:
		if directionDU == -1:
			animated_sprite_2d.play("RunUP")
		else:
			animated_sprite_2d.play("RunDown")
	else:
		if lastMovDirection == 0:
			animated_sprite_2d.play("IdleLato")
		elif lastMovDirection == -1:
			animated_sprite_2d.play("IdleUp")
		else:
			animated_sprite_2d.play("IdleDown")
###################################################################################################

### FUNZIONI PER GESTIONE INTERAZIONE #############################################################

func _on_interaction_area_area_entered(area):
	all_interations.insert(0, area)
	update_interactions()

func _on_interaction_area_area_exited(area):
	all_interations.erase(area)
	update_interactions()
	
func update_interactions():
	if all_interations:
		interact_label.text = all_interations[0].interaction_label
	else:
		interact_label.text = ""
		
func execute_interaction():
	if all_interations:
		var cur_interuction = all_interations[0]
		match cur_interuction.interaction_type:
			"Dialogic.start" : call_dialogic(cur_interuction.interaction_value)
			"change_scene" : get_tree().change_scene_to_file(cur_interuction.interaction_value)
			
###################################################################################################

### FUNZIONE PER GESTIONE DIALOGO #################################################################

func call_dialogic(value):
	canMove = false
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(value)

func _on_timeline_ended():
	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	canMove = true
	# do something else here

