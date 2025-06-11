extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	Transition.load_scene("res://Scenes/levels.tscn")


func _on_options_button_pressed() -> void:
	Transition.load_scene("res://Scenes/options.tscn")



func _on_exit_button_pressed() -> void:
	get_tree().quit()



func _on_tutorial_pressed() -> void:
	Transition.load_scene("res://Scenes/tutorial.tscn")
