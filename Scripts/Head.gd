class_name Head
extends Area2D


var input_dir: Dictionary = {
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
	"move_left": Vector2.LEFT,
	"move_right": Vector2.RIGHT
}


var tw: Tween
var can_move: bool = true
var current_dir: Vector2 = input_dir["move_right"]
@onready var turn = $Turn # For "Game" to access


var grid_size: int = 32
var speed: float = 8.0
var rot_speed: float


func _unhandled_input(event):
	# Iterate through our "input_dir" dictionary and check which action was pressed
	for key in input_dir:
		if event.is_action_pressed(key):
			# Set the current direction equal to the vector corresponding to the key in the dictionary
			current_dir = input_dir[key]
			$Turn.play()


func _process(delta):
	# Rotation speed must equal movement speed
	rot_speed = speed
	
	if can_move:
		# "can_move" is used to play the tween once
		SignalBus.has_moved.emit(speed)
		can_move = false
		# In case the player quickly changes the direction
		# Make sure the current direction does not equal the opposite direction
		# We don't want the player to do a full 180 degree turn
		# We use "is_equal_approx" to account for floating point errors
		if not transform.x.is_equal_approx(current_dir * -1):
			tw = create_tween().set_parallel()
			# You can reciprocate a value by dividing it by 1
			# Here, speed is divided by 1, hence, the larger the speed, the faster the tween
			tw.tween_property(self, "position", position + current_dir * grid_size, 1.0/speed)
			tw.tween_property(self, "rotation", transform.x.angle_to(current_dir), 1.0/rot_speed
				).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).as_relative()
		else:
			# If the player somehow quickly changed the direction to be opposite, ignore it
			# Instead, move in the direction the player is currently facing (ie. transform.x)
			tw = create_tween()
			tw.tween_property(self, "position", position + transform.x * grid_size, 1.0/speed)
		# Wait until the tween is finished, then move the player again
		await tw.finished
		can_move = true
