class_name Segment
extends Area2D


var is_active: bool = false


func _ready():
	SignalBus.has_moved.connect(_on_player_moved)


func _on_player_moved(speed: float):
	# Play a tween when the segment first gets created and once the player has moved
	if not is_active:
		var tw: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0/speed).from(Vector2(0.0, 0.0))
		await tw.finished
		is_active = true


func _on_area_entered(area):
	if area is Head and is_active:
		SignalBus.game_lost.emit()
