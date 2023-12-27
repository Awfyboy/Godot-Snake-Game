extends Node

# This is an Autoload containing necessary signals for the game

signal apple_eaten # Player eats apple
signal has_moved(speed: float) # Player has moved
signal respawn_apple_requested # Apple spawned inside snake, request new apple
signal game_lost # Player has lost the game
