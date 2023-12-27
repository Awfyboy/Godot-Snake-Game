class_name Apple
extends Area2D


func _process(delta):
	# If the apple spawned inside of a segment or the head or another apple, request a new apple
	# Repeat this process until it finds an empty space
	# Note: "get_overlapping_areas" returns an array, hence we use "pop_front" to get the first element
	if get_overlapping_areas().pop_front() is Segment:
		print("Apple spawned inside another object. Requesting new apple...")
		SignalBus.respawn_apple_requested.emit()
		queue_free()


func _on_area_entered(area):
	if area is Head:
		# Wait until the snake head's tween has finished
		# After that, emit the signal and delete this apple
		await area.tw.finished
		SignalBus.apple_eaten.emit()
		queue_free()

