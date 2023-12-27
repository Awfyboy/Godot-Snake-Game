extends Node2D


@onready var snake = $Snake
@onready var head = $Snake/Head
@onready var time = $CanvasLayer/UI/Time
@onready var time_timer = $CanvasLayer/UI/Time/TimeTimer
@onready var input_display = $CanvasLayer/UI/InputDisplay
@onready var score_text = $CanvasLayer/UI/Score/ScoreText
@onready var apples = $Apples
@onready var game_over = $CanvasLayer/GameOver
@onready var game_over_time = $CanvasLayer/GameOver/VBoxContainer/GameOverTime
@onready var game_over_score = $CanvasLayer/GameOver/VBoxContainer/GameOverScore


var input_dir: Dictionary = {
	"move_up": preload("res://Sprites/MovementUp.png"),
	"move_down": preload("res://Sprites/MovementDown.png"),
	"move_left": preload("res://Sprites/MovementLeft.png"),
	"move_right": preload("res://Sprites/MovementRight.png")
}


@export_range(6.0, 18.0, 0.1) var player_speed: float = 12.0
@export_range(0, 10) var initial_segment_count: int = 3
var tw: Tween
var grid_size: int = 32
var score: int = 0
var seconds: int = 0
var minutes: int = 0


func _ready():
	SignalBus.apple_eaten.connect(_on_apple_eaten)
	SignalBus.has_moved.connect(_on_player_moved)
	SignalBus.respawn_apple_requested.connect(create_apple)
	SignalBus.game_lost.connect(_on_game_lost)
	
	head.speed = player_speed
	
	create_apple()
	for i in initial_segment_count:
		create_segment()


func _unhandled_input(event):
	# Update "InputDisplay" to show the last button pressed
	for key in input_dir:
		if event.is_action_pressed(key):
			# Set the texture equal to the image resource corresponding to the key in the dictionary
			input_display.texture = input_dir[key]
	
	# Restart game
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_apple_eaten():
	# Increase score when player eats an apple
	score += 1
	score_text.text = "x" + str(score)
	
	# Add some randomness to the Eat sound
	$Eat.pitch_scale = randf_range(1.0, 1.4)
	$Eat.play()
	
	# Create a new apple and a new segment
	create_apple()
	create_segment()


# This is the function that moves the segments like a snake
func _on_player_moved(speed: float):
	# First, check if the snake has at least one segment apart from the head
	if snake.get_child_count() > 1:
		tw = create_tween().set_parallel()
		var segment_positions = get_segment_positions()
		
		for segment_index in snake.get_child_count():
			var selected_segment = snake.get_child(segment_index)
			# Check if the segment is a not the head, basically
			if selected_segment is Segment:
				# The segment should tween to the position of the segment that is in front of it, and that's it!
				tw.tween_property(selected_segment, "position", segment_positions[segment_index-1], 1.0/speed)


func _on_game_lost():
	# Stop the player from moving and display the game over screen
	head.can_move = false
	game_over.show()
	input_display.hide()
	head.turn.volume_db = -80
	$Lose.play()
	
	# Update the time and score texts to dsiaply the final results
	game_over_time.text = "TIME: " + time.text
	game_over_score.text = "SCORE: " + str(score)
	time_timer.stop()
	
	# Make sure to stop the snake's tween movement (including the head's)
	if tw:
		tw.stop()
		head.tw.stop()


func _process(delta):
	# String formatting for the time label
	# Check out the docs for more info:
	# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
	var temp_seconds: String = "%0*d" % [2, seconds]
	var temp_minutes: String = "%0*d" % [2, minutes] 
	time.text = "TIME: " + temp_minutes + ":" + temp_seconds



func create_apple():
	var apple = preload("res://Scenes/Apple.tscn").instantiate()
	
	# Select a random position inside the play area
	apple.position.x = randi_range(80, 720)
	apple.position.y = randi_range(144, 720)
	
	# Snap the position based on the grid size
	# Note that the apple's Sprite2D and CollisionShape2D has been offset so that it looks correct
	apple.position.x = snapped(apple.position.x, grid_size)
	apple.position.y = snapped(apple.position.y, grid_size)
	
	# Add apple to scene
	apples.call_deferred("add_child", apple)



func create_segment():
	var segment = preload("res://Scenes/Segment.tscn").instantiate()
	
	# Move segment to last child
	segment.position = get_tail().position
	
	# Increment every segments' z-index by 1
	# This makes sure that the earliest segment is on top of the next one
	for selected_segment in snake.get_children():
		selected_segment.z_index += 1
	
	# Add segment to scene
	snake.call_deferred("add_child", segment)


func get_segment_positions():
	# Get position of all segments in the snake
	var snake_body: Array = snake.get_children()
	var segment_positions: Array
	for segment in snake_body:
		segment_positions.append(segment.position)
	return segment_positions


func get_tail():
	return snake.get_children().pop_back()


func _on_time_timer_timeout():
	seconds += 1
	if seconds >= 60:
		seconds = 0
		minutes += 1


func _on_border_area_entered(area):
	if area is Head:
		SignalBus.game_lost.emit()
