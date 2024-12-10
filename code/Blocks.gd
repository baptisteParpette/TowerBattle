extends RigidBody3D

var is_moving = true
var base_speed = 5.0
var speed_multiplier = 1.0
var direction_x = 1
var direction_z = 1
var move_on_x = true
var block_size = Vector3(3, 0.5, 3)
var previous_block = null
var base_color: Color
var next_color: Color
static var last_base_color: Color
var movement_bounds = Vector2()  
 
func _ready():
	add_to_group("blocks")

	collision_layer = 4
	collision_mask = 4 | 2
	
	if previous_block:
		if previous_block.position.x < 0:  
			movement_bounds = Vector2(-8, -2)  
		else:  
			movement_bounds = Vector2(17, 23)  
	
	if !previous_block:
		is_moving = false
		base_color = Color(randf(), randf(), randf())
		last_base_color = base_color
		next_color = generate_next_color(base_color)
	else:
		base_color = previous_block.next_color
		next_color = generate_next_color(base_color)
	
	gravity_scale = 0.0
	freeze = true
	
	if previous_block:
		block_size = Vector3(
			previous_block.block_size.x,
			block_size.y,
			previous_block.block_size.z
		)
	
	setup_block()

func generate_next_color(current_color: Color) -> Color:
	var hue_shift = randf_range(-0.1, 0.1)  
	var new_h = fposmod(current_color.h + hue_shift, 1.0)
	var new_s = clamp(current_color.s + randf_range(-0.1, 0.1), 0.5, 1.0)
	var new_v = clamp(current_color.v + randf_range(-0.1, 0.1), 0.5, 1.0)
	return Color.from_hsv(new_h, new_s, new_v)


func setup_block():
	
	for child in get_children():
		child.queue_free()
	
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = block_size  
	mesh.mesh = box
	
	
	var material = StandardMaterial3D.new()
	var height_factor = position.y / 20.0
	material.albedo_color = base_color.lerp(next_color, height_factor)
	mesh.material_override = material
	add_child(mesh)
	
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = block_size  
	collision.shape = shape
	add_child(collision)
	

func update_color():
	if has_node("MeshInstance3D"):
		var mesh = get_node("MeshInstance3D")
		if mesh.material_override:
			var height_factor = position.y / 20.0
			mesh.material_override.albedo_color = base_color.lerp(next_color, height_factor)

func _physics_process(delta):
	if is_moving:
		var current_speed = base_speed * speed_multiplier
		
		if move_on_x:
			
			if position.x < 0:
				position.x += current_speed * direction_x * delta
				if position.x > -2:  
					direction_x = -1
				elif position.x < -8:
					direction_x = 1
			
			else:
				position.x += current_speed * direction_x * delta
				if position.x > 23:
					direction_x = -1
				elif position.x < 17:
					direction_x = 1
		else:
			
			if position.x < 0:
				position.z += current_speed * direction_z * delta
				if position.z > 3:
					direction_z = -1
				elif position.z < -3:
					direction_z = 1
			
			else:
				position.z += current_speed * direction_z * delta
				if position.z > 18:
					direction_z = -1
				elif position.z < 12:
					direction_z = 1
					
		update_color()

func stop_moving():
	is_moving = false
	if previous_block:
		if move_on_x:
			position.z = previous_block.position.z
		else:
			position.x = previous_block.position.x
		var success = cut_block_on_axis('x' if move_on_x else 'z')
		
		
		var game_manager = get_node("/root/Main/GameManager")
		if game_manager:
			game_manager.recalculate_tower_height(position.x < 0)
		
		return success
	
	freeze = true
	return true

func cut_block_on_axis(axis: String):
	var current_pos = position[axis]
	var current_size = block_size[axis]
	var prev_pos = previous_block.position[axis]
	var prev_size = previous_block.block_size[axis]
	
	var falling_speed_reduction = 0.3 
	
	var tolerance = 0.1  
	
	var minimum_size = 0  
	
	var current_start = current_pos - (current_size / 2)
	var current_end = current_pos + (current_size / 2)
	var prev_start = prev_pos - (prev_size / 2)
	var prev_end = prev_pos + (prev_size / 2)
	
	if abs(current_pos - prev_pos) < tolerance:
		if axis == 'x':
			position.x = prev_pos
		else:
			position.z = prev_pos
		return true
	
	if current_start > prev_end or current_end < prev_start:
		freeze = false
		gravity_scale = 1.0
		return false
	
	
	var new_start = max(current_start, prev_start)
	var new_end = min(current_end, prev_end)
	var new_size = new_end - new_start
	
	if new_size < minimum_size:
		freeze = false
		gravity_scale = 1.0
		return false
	
	var new_pos = new_start + (new_size / 2)
	
	
	var falling_block = duplicate()
	get_parent().add_child(falling_block)
	
	
	falling_block.previous_block = null
	falling_block.is_moving = false
	falling_block.freeze = false
	falling_block.gravity_scale = 1.0
	falling_block.base_color = base_color
	falling_block.next_color = next_color
	
	
	if axis == 'x':
		if current_pos > prev_pos:
			
			falling_block.block_size = Vector3(
				current_end - prev_end,
				block_size.y,
				block_size.z
			)
			falling_block.position = Vector3(
				prev_end + falling_block.block_size.x/2,
				position.y,
				position.z
			)
			falling_block.linear_velocity.x = base_speed * speed_multiplier * direction_x * falling_speed_reduction
		else:
			
			falling_block.block_size = Vector3(
				prev_start - current_start,
				block_size.y,
				block_size.z
			)
			falling_block.position = Vector3(
				prev_start - falling_block.block_size.x/2,
				position.y,
				position.z
			)
			falling_block.linear_velocity.x = base_speed * speed_multiplier * direction_x * falling_speed_reduction
	else:
		if current_pos > prev_pos:
			
			falling_block.block_size = Vector3(
				block_size.x,
				block_size.y,
				current_end - prev_end
			)
			falling_block.position = Vector3(
				position.x,
				position.y,
				prev_end + falling_block.block_size.z/2
			)
			falling_block.linear_velocity.z = base_speed * speed_multiplier * direction_z * falling_speed_reduction
		else:
			
			falling_block.block_size = Vector3(
				block_size.x,
				block_size.y,
				prev_start - current_start
			)
			falling_block.position = Vector3(
				position.x,
				position.y,
				prev_start - falling_block.block_size.z/2
			)
			
			falling_block.linear_velocity.z = -base_speed * speed_multiplier * direction_z * falling_speed_reduction
	
	falling_block.setup_block()
	
	
	if axis == 'x':
		block_size.x = new_size
		position.x = new_pos
	else:
		block_size.z = new_size
		position.z = new_pos
	
	setup_block()
	freeze = true
	
	
	create_tween().tween_callback(falling_block.queue_free).set_delay(3.0)
	
	return true

func reduce_size(reduction_factor: float):

	
	var new_size = Vector3(
		block_size.x * (1.0 - reduction_factor),
		block_size.y,
		block_size.z * (1.0 - reduction_factor)
	)
	


	
	block_size = new_size
	setup_block()  