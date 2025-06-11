extends Node

# Declare variables at the top level of the script
var starting_deck = ["knight", "goblin", "dragon", "knight", "Tornado", "knight", "Tornado", "Tornado"]
var chosen_path: String = ""        # Stores which path player chose
var total_money: int = 15         # Tracks money earned across battles
var unlocked_levels: Array = [1]    # Optional - unlocked levels
var current_level: int = 1          # Optional - track current level
var game_tracker: int = 1          #tracks how many times the scene has changed - it reloads
var godmode = false
var boss = false
var rng1 = RandomNumberGenerator.new()
var rng2 = RandomNumberGenerator.new()
var rng3 = RandomNumberGenerator.new()

func _init():
	rng1.randomize()
	rng2.randomize()
	rng3.randomize()

func get_num1() -> int:
	return rng1.randi_range(1, 2)

func get_num2() -> int:
	return rng2.randi_range(1, 2)

func get_num3() -> int:
	return rng3.randi_range(1, 2)

#Unused code below

	#if num1 == 1:
		#get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#else:
		#get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
		#pass
		#
#
#
	#if num2 == 1:
		#get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#else:
		#get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
		#pass
#
#
	#if num3 == 1:
		#get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#else:
		#get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
		#pass
