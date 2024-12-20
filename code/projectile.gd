extends RigidBody3D

var launch_force = 20.0
var damage = 10.0
var trajectory_points = []  
var initial_velocity = Vector3.ZERO

func _ready():
	collision_layer = 2
	collision_mask = 4  
	print;;("INIT")

func launch(initial_velocity: Vector3):
	self.initial_velocity = initial_velocity
	linear_velocity = initial_velocity

func _physics_process(_delta):
	for body in get_colliding_bodies():

		if body.is_in_group("blocks"):

			_on_body_entered(body)


func _on_body_entered(body):

	if body is RigidBody3D and body.is_in_group("blocks"):

		
		
		var game_manager = get_node("/root/Main/GameManager")
		var reduction_factor = 0.05  
		
		
		var is_p1_tower = body.position.x < 0
		
		
		if (is_p1_tower and !game_manager.p1_alive) or (!is_p1_tower and !game_manager.p2_alive):
			queue_free()  
			return
			
		var current_moving_block = game_manager.current_block_p1 if is_p1_tower else game_manager.current_block_p2
		var base_block = game_manager.last_block_p1 if is_p1_tower else game_manager.last_block_p2
		

		
		
		if current_moving_block and is_instance_valid(current_moving_block):

			current_moving_block.reduce_size(reduction_factor)
		
		
		
		var current_block = base_block
		while current_block != null and is_instance_valid(current_block):

			current_block.reduce_size(reduction_factor)
			current_block = current_block.previous_block
			
			
			if current_block and !is_instance_valid(current_block):
				break
		

		queue_free()  

func calculate_trajectory(steps: int = 50, time_step: float = 0.1) -> Array:
	var points = []
	var pos = position
	var vel = initial_velocity
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * Vector3.DOWN
	
	for i in range(steps):
		points.append(pos)
		vel += gravity * time_step
		pos += vel * time_step
		
	return points
