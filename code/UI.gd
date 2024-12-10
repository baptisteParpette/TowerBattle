extends Control

@onready var score_label = get_node("Label")
@onready var winner_label = $"../WinnerLabel"
var progress_container: ColorRect
var progress_fill: ColorRect
var progress_container_opponent: ColorRect
var progress_fill_opponent: ColorRect
var my_score_label: Label
var opponent_score_label: Label
var cooldown_indicator: Label

func _ready():
	if winner_label:
		winner_label.hide()

	if score_label:
		score_label.set_position(Vector2(10, 10))
		var player_color = Color(1.0, 0.3, 0.3) if "P2" in name else Color(0.2, 0.6, 1.0)
		score_label.text = "Player " + ("2" if "P2" in name else "1") + " - Target Score: " + str(get_node("/root/Main/GameManager").target_score)
		score_label.add_theme_color_override("font_color", player_color)
	
	
	progress_container = ColorRect.new()
	progress_container.set_position(Vector2(10, 40))
	progress_container.set_size(Vector2(300, 20))
	progress_container.color = (Color(1.0, 0.3, 0.3, 0.3) if "P2" in name else Color(0.2, 0.6, 1.0, 0.3))
	add_child(progress_container)
	
	progress_fill = ColorRect.new()
	progress_fill.set_position(Vector2(0, 0))
	progress_fill.set_size(Vector2(0, 20))
	progress_fill.color = Color(1.0, 0.3, 0.3) if "P2" in name else Color(0.2, 0.6, 1.0)
	progress_container.add_child(progress_fill)
	
	
	var my_label = Label.new()
	my_label.text = "ME"
	my_label.add_theme_color_override("font_color", Color.WHITE)
	my_label.set_position(Vector2(5, -2))
	progress_container.add_child(my_label)
	
	
	my_score_label = Label.new()
	my_score_label.set_position(Vector2(320, 40))
	my_score_label.add_theme_color_override("font_color", progress_fill.color)
	add_child(my_score_label)
	
	
	progress_container_opponent = ColorRect.new()
	progress_container_opponent.set_position(Vector2(10, 60))
	progress_container_opponent.set_size(Vector2(300, 20))
	progress_container_opponent.color = (Color(0.2, 0.6, 1.0, 0.3) if "P2" in name else Color(1.0, 0.3, 0.3, 0.3))
	add_child(progress_container_opponent)
	
	progress_fill_opponent = ColorRect.new()
	progress_fill_opponent.set_position(Vector2(0, 0))
	progress_fill_opponent.set_size(Vector2(0, 20))
	progress_fill_opponent.color = Color(0.2, 0.6, 1.0) if "P2" in name else Color(1.0, 0.3, 0.3)
	progress_container_opponent.add_child(progress_fill_opponent)
	
	
	var opponent_label = Label.new()
	opponent_label.text = "OPPONENT"
	opponent_label.add_theme_color_override("font_color", Color.WHITE)
	opponent_label.set_position(Vector2(5, -2))
	progress_container_opponent.add_child(opponent_label)
	
	
	opponent_score_label = Label.new()
	opponent_score_label.set_position(Vector2(320, 55))
	opponent_score_label.add_theme_color_override("font_color", progress_fill_opponent.color)
	add_child(opponent_score_label)
	
	
	cooldown_indicator = Label.new()
	cooldown_indicator.set_position(Vector2(10, 85))
	cooldown_indicator.add_theme_color_override("font_color", Color.GREEN)
	cooldown_indicator.text = "Projectile Ready!"
	add_child(cooldown_indicator)

func update_score(score: int, player_number: int = 1):
	if player_number == -1:
		player_number = 2 if "P2" in name else 1
	else:
		player_number = 2 if "P2" in name else 1

	var game_manager = get_node("/root/Main/GameManager")
	var target_score = game_manager.target_score

	
	var my_width = (score / float(target_score)) * 300
	progress_fill.set_size(Vector2(my_width, 20))
	
	
	my_score_label.text = str(score)

func update_cooldown(percent: float):
	if cooldown_indicator:
		if percent >= 100:
			cooldown_indicator.text = "Projectile Ready!"
			cooldown_indicator.add_theme_color_override("font_color", Color.BLACK)
		else:
			cooldown_indicator.text = "Cooldown: %d%%" % percent
			cooldown_indicator.add_theme_color_override("font_color", Color.RED)

func show_winner_message(player_number: int):
	if winner_label:
		if player_number == 0:
			winner_label.text = "IT'S A TIE!\n\nPress R to restart\nPress Q to quit"
		else:
			winner_label.text = "PLAYER %d WINS!\n\nPress R to restart\nPress Q to quit" % player_number
		winner_label.show()

func hide_winner_message():
	if winner_label:
		winner_label.hide()

func _process(_delta):
	var game_manager = get_node("/root/Main/GameManager")
	var target_score = game_manager.target_score
	
	
	var is_p2 = "P2" in name
	
	
	var opponent_score = game_manager.score_p1 if is_p2 else game_manager.score_p2
	
	
	var opponent_width = (opponent_score / float(target_score)) * 300
	
	
	progress_fill_opponent.set_size(Vector2(opponent_width, 20))
	opponent_score_label.text = str(opponent_score)
