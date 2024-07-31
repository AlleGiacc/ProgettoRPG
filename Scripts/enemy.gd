
extends CharacterBody2D

const LEFT  : int = -1
const RIGHT : int =  1

var can_move			: bool

var Name				: String
var Speed 				: int
var Status 				: String
var PrevStatus 			: String
var Direction 			: int
var LastPostionKnown	: Vector2
var LastDirectionKnow	: bool
var BodyToChase 		: Player
@onready var AnimatedSprite2d 	: AnimatedSprite2D 	 = $AnimatedSprite2D
@onready var CollisionPolygon2d : CollisionPolygon2D = $DetectionArea/CollisionPolygon2D
@onready var PathToFollow 		: PathFollow2D 		 = get_parent() as PathFollow2D

#==============================================================================
func _init():
	Name 				= "Slime"
	PrevStatus 			= ""
	Status 				= "idle"
	Speed 				= 70
	Direction 			= RIGHT
	BodyToChase 		= null	
	
	
#==============================================================================
func _ready():	
	AnimatedSprite2d.play("walk")
	LastPostionKnown = global_position

#==============================================================================
func _physics_process(delta):
	match Status:
		"idle":
			patrol_path(delta)
		"chase":
			if ( can_move == false ):
				# fai partire l'animazione del punto esclamativo
				AnimatedSprite2d.play("approaching")							
				# aspetta 1000 ms
				await get_tree().create_timer(1).timeout
				# ritorna alla velocità corretta	
				if ( BodyToChase != null ):
					# fai partire l'animazione dell'inseguimento
					AnimatedSprite2d.play("walk")								
				else:
					# altrimenti lo fermi per un bel po'	
					AnimatedSprite2d.play("idle")					
					# TO-DO ---- fare parte in cui si arresta a causa di un errore -----------------
					#-------------------------------------------------------------------------------
				# deve eseguirsi solo una volta
				can_move = true
				
			chasing(delta)
		"return":
			return_to_path(delta)
	
	if ( PrevStatus != Status ):
		PrevStatus = Status
		print ( Name + "> " + Status )
	
	move_and_slide()

#==============================================================================
func return_to_path(delta):
	var _lastLocation = (LastPostionKnown - global_position).normalized()	
	
	velocity = _lastLocation * Speed
	if global_position.distance_to(LastPostionKnown) < 1:
		global_position = LastPostionKnown
		Status = "idle"
		
	if (LastPostionKnown.x - global_position.x) < 0:
		AnimatedSprite2d.flip_h = true
	else:
		AnimatedSprite2d.flip_h = false
		
	update_collision_polygon()

#==============================================================================
func chasing(delta):
	update_collision_polygon()
	var _PlayerLocation = (BodyToChase.global_position - global_position).normalized()
	
	velocity = _PlayerLocation * Speed
	if _PlayerLocation.x < 0:
		AnimatedSprite2d.flip_h = true	
	else:
		AnimatedSprite2d.flip_h = false

#==============================================================================
func patrol_path(delta):
	const TURN_LEFT  = 1
	const TURN_RIGHT = 0
	
	velocity = Vector2.ZERO	
	
	if Direction == RIGHT: 
		if PathToFollow.progress_ratio >= TURN_LEFT:
			Direction = LEFT
			AnimatedSprite2d.flip_h = true		
		else:
			PathToFollow.set_progress(PathToFollow.get_progress() + Speed * delta)
	
	if Direction == LEFT: 
		if PathToFollow.progress_ratio <= TURN_RIGHT:
			Direction = RIGHT
			AnimatedSprite2d.flip_h = false
		else:
			PathToFollow.set_progress(PathToFollow.get_progress() - Speed * delta)
			
	update_collision_polygon()

#==============================================================================
func update_collision_polygon():
	match Status:
		"idle":
			var movement_direction = (global_position - LastPostionKnown).normalized()
			CollisionPolygon2d.look_at(global_position + movement_direction)
			LastPostionKnown = global_position
		"chase":
			CollisionPolygon2d.look_at(BodyToChase.global_position)
		"return":
			CollisionPolygon2d.look_at(LastPostionKnown)	


#==============================================================================
func _on_detection_area_body_entered(body):
	# il Player è stato rilevato?
	if body is Player:
		# cambio lo stato
		Status = "chase"
		can_move = false
		# so chi devo inseguire ora
		BodyToChase = body

#==============================================================================
func _on_detection_area_body_exited(body):
	# il Player non è più nel mio campo visivo?
	if body is Player:
		# cambia stato
		Status = "return"
		# non c'è più nessuno da inseguire D:
		BodyToChase = null

#==============================================================================
func _on_collision_area_body_entered(body):
	# il player ha avuto una interazione con me?
	if body is Player:
		# cambia lo stato
		Status = "fight"
		_on_player_battle_start(false)

#==============================================================================
# meglio dividere in 2 funzioni? una che cattura il segnale a altra che fa logica?
func _on_player_battle_start(attacked):
	Status = "fight"
	if attacked:
		if Status == "chase":
			print("battaglia normale")
		else:
			print("battaglia vantaggio")
	else:
		print("battaglia con svantaggio")
