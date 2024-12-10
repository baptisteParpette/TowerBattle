extends Node3D

var Block = preload("res://Block.tscn")
var Projectile = preload("res://projectile.tscn")

@onready var camera_p1 = $"../ViewportLayout/SubViewportContainer1/SubViewport1/CameraP1"
@onready var camera_p2 = $"../ViewportLayout/SubViewportContainer2/SubViewport2/CameraP2"
@onready var ui_p1 = $"../ViewportLayout/SubViewportContainer1/ControlP1"
@onready var ui_p2 = $"../ViewportLayout/SubViewportContainer2/ControlP2"
@onready var winner_label = $"../WinnerLabel"


var can_spawn_p1 = true
var can_spawn_p2 = true
var alternate_movement_p1 = true
var alternate_movement_p2 = true
var score_p1 = 0
var score_p2 = 0
var speed_increase_per_block = 0.1
var current_speed_multiplier_p1 = 1.0
var current_speed_multiplier_p2 = 1.0
var game_active = true

var target_score = 20  
var winner = 0  


var p1_alive = true
var p2_alive = true
var game_ended = false


var charging_power_p1 = false
var charging_power_p2 = false






var trajectory_line_p1: Node3D
var trajectory_line_p2: Node3D


var current_block_p1 = null
var current_block_p2 = null
var last_block_p1 = null
var last_block_p2 = null
var stack_height_p1 = 0.0
var stack_height_p2 = 0.0


var projectile_timer_p1: Timer
var projectile_timer_p2: Timer
var can_shoot_p1 = false
var can_shoot_p2 = false


var oscillation_speed = 0.3  

var min_angle = PI/30  
var max_angle = PI/6 
var current_angle_p1 = 0.0
var current_angle_p2 = 0.0
var oscillation_direction_p1 = 1.0  
var oscillation_direction_p2 = 1.0
const BASE_POWER = 20.0  


var cleanup_height = -10.0  

func _ready():	
	
	setup_projectile_timers()
	if winner_label:
		winner_label.hide()
	await get_tree().create_timer(0.1).timeout
	reset_game()
	setup_trajectory_lines()

	

func recalculate_tower_height(is_p1_tower: bool):
	if is_p1_tower:
		var max_height = 0.0
		
		
		for block in get_children():
			if block is RigidBody3D and block.position.x < 0:
				max_height = max(max_height, block.position.y)
		
		
		stack_height_p1 = max_height
		if camera_p1:
			camera_p1.update_height(stack_height_p1)
			
	else:
		var max_height = 0.0
		
		for block in get_children():
			if block is RigidBody3D and block.position.x > 0:
				max_height = max(max_height, block.position.y)
		
		
		stack_height_p2 = max_height
		if camera_p2:
			camera_p2.update_height(stack_height_p2)
	
	check_game_state()

func setup_trajectory_lines():
	
	var TrajectoryLine = load("res://TrajectoryLine.gd")
	
	trajectory_line_p1 = Node3D.new()
	trajectory_line_p1.set_script(TrajectoryLine)
	add_child(trajectory_line_p1)
	
	trajectory_line_p2 = Node3D.new()
	trajectory_line_p2.set_script(TrajectoryLine)
	add_child(trajectory_line_p2)

func setup_projectile_timers():
	projectile_timer_p1 = Timer.new()
	projectile_timer_p1.wait_time = 10.0
	projectile_timer_p1.connect("timeout", _on_projectile_timer_timeout.bind(1))
	add_child(projectile_timer_p1)
	
	projectile_timer_p2 = Timer.new()
	projectile_timer_p2.wait_time = 10.0
	projectile_timer_p2.connect("timeout", _on_projectile_timer_timeout.bind(2))
	add_child(projectile_timer_p2)
	
	projectile_timer_p1.start()
	projectile_timer_p2.start()

func _on_projectile_timer_timeout(player_num: int):
	if player_num == 1:
		can_shoot_p1 = true
	else:
		can_shoot_p2 = true

func spawn_projectile(player_num: int):
	var start_pos: Vector3
	var trajectory_line: Node3D
	var angle: float
	var target_pos: Vector3
	
	if player_num == 1:
		start_pos = Vector3(
			-3,  
			1,
			2
		)
		target_pos = Vector3(
			20,
			last_block_p2.position.y,
			15
		)
		trajectory_line = trajectory_line_p1
		angle = current_angle_p1
	else:
		start_pos = Vector3(
			18,  
			1,
			13
		)
		target_pos = Vector3(
			-5,
			last_block_p1.position.y,
			0
		)
		trajectory_line = trajectory_line_p2
		angle = current_angle_p2
	
	
	var direction_to_target = (target_pos - start_pos).normalized()
	direction_to_target.y = 0
	
	
	var launch_direction = Vector3(
		direction_to_target.x,
		tan(angle),
		direction_to_target.z
	).normalized()
	
	
	var distance = start_pos.distance_to(target_pos)
	var adjusted_power = BASE_POWER * (distance / 20.0)
	
	var projectile = Projectile.instantiate()
	add_child(projectile)
	projectile.position = start_pos  
	projectile.launch(launch_direction * adjusted_power)
	
	
	if player_num == 1:
		charging_power_p1 = false
		current_angle_p1 = min_angle
		oscillation_direction_p1 = 1.0
		trajectory_line.clear()
	else:
		charging_power_p2 = false
		current_angle_p2 = min_angle
		oscillation_direction_p2 = 1.0
		trajectory_line.clear()

func reset_game():
	var overlay = get_node("../GameOverOverlay")
	if overlay:
		overlay.hide()
		
	if winner_label:
		winner_label.hide()

	for child in get_children():
		if child is RigidBody3D:
			child.queue_free()
	
	
	winner = 0  
	score_p1 = 0
	score_p2 = 0
	current_speed_multiplier_p1 = 1.0
	current_speed_multiplier_p2 = 1.0
	game_active = true
	stack_height_p1 = 0.0
	stack_height_p2 = 0.0
	p1_alive = true
	p2_alive = true
	game_ended = false
	can_spawn_p1 = true
	can_spawn_p2 = true
	alternate_movement_p1 = true
	alternate_movement_p2 = true
	current_block_p1 = null
	current_block_p2 = null
	last_block_p1 = null
	last_block_p2 = null
	
	
	can_shoot_p1 = false  
	can_shoot_p2 = false  
	charging_power_p1 = false
	charging_power_p2 = false	
	
	
	projectile_timer_p1.stop()
	projectile_timer_p2.stop()
	projectile_timer_p1.start()  
	projectile_timer_p2.start()  
	
	
	if ui_p1:
		ui_p1.hide_winner_message()
		ui_p1.update_score(score_p1)
		ui_p1.update_cooldown(0)  
	if ui_p2:
		ui_p2.hide_winner_message()
		ui_p2.update_score(score_p2)
		ui_p2.update_cooldown(0)  
		
	
	if trajectory_line_p1:
		trajectory_line_p1.clear()
	if trajectory_line_p2:
		trajectory_line_p2.clear()
		
	
	await get_tree().create_timer(0.1).timeout
	
	
	spawn_base_block(1)
	spawn_base_block(2)
	await get_tree().create_timer(0.2).timeout
	spawn_new_block(1)
	spawn_new_block(2)

func spawn_base_block(player_num: int):
	var base = Block.instantiate()
	add_child(base)
	if player_num == 1:
		base.position = Vector3(-5, 0.25, 0)  
		last_block_p1 = base
		if camera_p1:
			camera_p1.update_height(0)
	else:
		base.position = Vector3(20, 0.25, 15)  
		last_block_p2 = base
		if camera_p2:
			camera_p2.update_height(0)
	base.is_moving = false
	base.freeze = true

func spawn_new_block(player_num: int):
	await get_tree().create_timer(0.2).timeout
	if player_num == 1 and can_spawn_p1 and game_active:
		current_block_p1 = Block.instantiate()
		current_block_p1.previous_block = last_block_p1
		current_block_p1.move_on_x = alternate_movement_p1
		current_block_p1.speed_multiplier = current_speed_multiplier_p1
		
		
		if last_block_p1:
			current_block_p1.block_size = Vector3(
				last_block_p1.block_size.x,
				current_block_p1.block_size.y,
				last_block_p1.block_size.z
			)
		
		current_block_p1.is_moving = true
		add_child(current_block_p1)

		var spawn_pos = Vector3(
			-12 if alternate_movement_p1 else last_block_p1.position.x,
			last_block_p1.position.y + current_block_p1.block_size.y,
			
			last_block_p1.position.z + (3 if !alternate_movement_p1 else 0)
		)

		current_block_p1.position = spawn_pos
		alternate_movement_p1 = !alternate_movement_p1
		
	elif player_num == 2 and can_spawn_p2 and game_active:
		current_block_p2 = Block.instantiate()
		current_block_p2.previous_block = last_block_p2
		current_block_p2.move_on_x = alternate_movement_p2
		current_block_p2.speed_multiplier = current_speed_multiplier_p2
		
		
		if last_block_p2:
			current_block_p2.block_size = Vector3(
				last_block_p2.block_size.x,
				current_block_p2.block_size.y,
				last_block_p2.block_size.z
			)
			
		current_block_p2.is_moving = true
		add_child(current_block_p2)

		var spawn_pos = Vector3(
			13 if alternate_movement_p2 else last_block_p2.position.x,
			last_block_p2.position.y + current_block_p2.block_size.y,
			last_block_p2.position.z
		)
		
		current_block_p2.position = spawn_pos
		alternate_movement_p2 = !alternate_movement_p2

func game_over(player_num: int):
	if player_num == 1:
		p1_alive = false

	else:
		p2_alive = false

		
	
	check_game_state()

func update_score(player_num: int, new_score: int):
	if player_num == 1:
		ui_p1.update_score(new_score, 1)  
	else:
		ui_p2.update_score(new_score, 2)  

func check_game_state():
	
	if score_p1 >= target_score:
		game_ended = true
		winner = 1
		declare_winner()
		return
	
	if score_p2 >= target_score:
		game_ended = true
		winner = 2
		declare_winner()
		return
	
	
	if !p1_alive && !p2_alive:
		game_ended = true
		if score_p1 > score_p2:
			winner = 1
		elif score_p2 > score_p1:
			winner = 2
		else:
			winner = 0
		declare_winner()
		return
	
	
	if !p1_alive && p2_alive && score_p2 > score_p1:
		game_ended = true
		winner = 2
		declare_winner()
		return
			
	if !p2_alive && p1_alive && score_p1 > score_p2:
		game_ended = true
		winner = 1
		declare_winner()
		return

func declare_winner():
	var message = ""
	
	if winner == 0:
		message = "IT'S A TIE!\n\nPress R to restart\nPress C to quit"
	elif winner == 1 || winner == 2:
		if score_p1 >= target_score || score_p2 >= target_score:
			message = "PLAYER %d WINS!\nReached target score first!\n\nPress R to restart\nPress C to quit" % winner
		elif !p1_alive && !p2_alive:
			message = "PLAYER %d WINS!\nHighest tower!\n\nPress R to restart\nPress C to quit" % winner
		else:
			message = "PLAYER %d WINS!\nLast tower standing!\n\nPress R to restart\nPress C to quit" % winner
	
	
	var overlay = get_node("../GameOverOverlay")
	if overlay:
		overlay.show()
		var winner_label = overlay.get_node("WinnerLabel")
		if winner_label:
			winner_label.text = message

	
	if ui_p1:
		ui_p1.show_winner_message(winner)
	if ui_p2:
		ui_p2.show_winner_message(winner)




























func _input(event):

	if event.is_action_pressed("ui_c"):  
		if game_ended:  
			get_tree().change_scene_to_file("res://menu.tscn")
			return

	
	if event.is_action_pressed("ui_reset"):
		if game_ended:
			reset_game()
			return

	
	if event.is_action_pressed("ui_select_p1"):
		
		if p1_alive and current_block_p1 != null and is_instance_valid(current_block_p1):
			if current_block_p1.is_moving and !game_ended:
				if current_block_p1.stop_moving():
					can_spawn_p1 = false
					last_block_p1 = current_block_p1
					stack_height_p1 = current_block_p1.position.y
					camera_p1.update_height(stack_height_p1)
					if last_block_p1.freeze == true:
						score_p1 += 1
						update_score(1, score_p1)
						
						if score_p1 >= target_score:
							game_ended = true
							winner = 1
							declare_winner()
							return
							
						if !p2_alive:
							check_game_state()
						
						if !game_ended:
							current_speed_multiplier_p1 += speed_increase_per_block
							await get_tree().create_timer(0.5).timeout
							can_spawn_p1 = true
							spawn_new_block(1)
				else:
					game_over(1)
	
	
	if event.is_action_pressed("ui_select_p2"):
		
		if p2_alive and current_block_p2 != null and is_instance_valid(current_block_p2):
			if current_block_p2.is_moving and !game_ended:
				if current_block_p2.stop_moving():
					can_spawn_p2 = false
					last_block_p2 = current_block_p2
					stack_height_p2 = current_block_p2.position.y
					camera_p2.update_height(stack_height_p2)
					if last_block_p2.freeze == true:
						score_p2 += 1
						update_score(2, score_p2)
						
						if score_p2 >= target_score:
							game_ended = true
							winner = 2
							declare_winner()
							return
							
						if !p1_alive:
							check_game_state()
						
						if !game_ended:
							current_speed_multiplier_p2 += speed_increase_per_block
							await get_tree().create_timer(0.5).timeout
							can_spawn_p2 = true
							spawn_new_block(2)
				else:
					game_over(2)
	
	
	if event.is_action_pressed("p1_shoot") and can_shoot_p1 and p1_alive and !game_ended:
		charging_power_p1 = true
	elif event.is_action_released("p1_shoot") and charging_power_p1 and p1_alive and !game_ended:
		spawn_projectile(1)
		can_shoot_p1 = false
		projectile_timer_p1.start()
	
	
	if event.is_action_pressed("p2_shoot") and can_shoot_p2 and p2_alive and !game_ended:
		charging_power_p2 = true
	elif event.is_action_released("p2_shoot") and charging_power_p2 and p2_alive and !game_ended:
		spawn_projectile(2)
		can_shoot_p2 = false
		projectile_timer_p2.start()

func _physics_process(_delta):
	
	for child in get_children():
		if child is RigidBody3D and child.position.y < cleanup_height:
			child.queue_free()

func _process(delta):


	if game_ended:
		
		if trajectory_line_p1:
			trajectory_line_p1.clear()
		if trajectory_line_p2:
			trajectory_line_p2.clear()
		return

	
	if charging_power_p1:
		current_angle_p1 += oscillation_speed * delta * oscillation_direction_p1
		if current_angle_p1 >= max_angle:
			current_angle_p1 = max_angle
			oscillation_direction_p1 = -1.0
		elif current_angle_p1 <= min_angle:
			current_angle_p1 = min_angle
			oscillation_direction_p1 = 1.0
		update_trajectory_preview(1)
	
	
	if charging_power_p2:
		current_angle_p2 += oscillation_speed * delta * oscillation_direction_p2
		if current_angle_p2 >= max_angle:
			current_angle_p2 = max_angle
			oscillation_direction_p2 = -1.0
		elif current_angle_p2 <= min_angle:
			current_angle_p2 = min_angle
			oscillation_direction_p2 = 1.0
		update_trajectory_preview(2)

		
	if !can_shoot_p1:
		var time_left = projectile_timer_p1.time_left
		var percent = (1 - (time_left / projectile_timer_p1.wait_time)) * 100
		ui_p1.update_cooldown(percent)
	else:
		ui_p1.update_cooldown(100)
	
	
	if !can_shoot_p2:
		var time_left = projectile_timer_p2.time_left
		var percent = (1 - (time_left / projectile_timer_p2.wait_time)) * 100
		ui_p2.update_cooldown(percent)
	else:
		ui_p2.update_cooldown(100)

func update_trajectory_preview(player: int):
	var start_pos: Vector3
	var trajectory_line: Node3D
	var angle: float
	var target_pos: Vector3
	
	if player == 1:
		
		start_pos = Vector3(
			-3,  
			1,  
			2   
		)
		
		target_pos = Vector3(
			20,  
			last_block_p2.position.y,  
			15   
		)
		trajectory_line = trajectory_line_p1
		angle = current_angle_p1
	else:
		
		start_pos = Vector3(
			18,  
			1,   
			13   
		)
		
		target_pos = Vector3(
			-5,  
			last_block_p1.position.y,  
			0    
		)
		trajectory_line = trajectory_line_p2
		angle = current_angle_p2
	
	
	var direction_to_target = (target_pos - start_pos).normalized()
	direction_to_target.y = 0  
	
	
	var launch_direction = Vector3(
		direction_to_target.x,
		tan(angle),
		direction_to_target.z
	).normalized()
	
	
	var distance = start_pos.distance_to(target_pos)
	var adjusted_power = BASE_POWER * (distance / 20.0)  
	
	
	var initial_velocity = launch_direction * adjusted_power
	
	
	var points = calculate_trajectory_points(start_pos, initial_velocity)
	
	
	trajectory_line.draw_trajectory(points)

func calculate_trajectory_points(start_pos: Vector3, initial_velocity: Vector3, steps: int = 50, time_step: float = 0.1) -> Array:
	var points = []
	var pos = start_pos
	var vel = initial_velocity
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * Vector3.DOWN
	
	for i in range(steps):
		points.append(pos)
		vel += gravity * time_step
		pos += vel * time_step
	
	return points
