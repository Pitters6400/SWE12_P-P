extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_continue_pressed() -> void:
	$No1.visible = false


func _on_continue_2_pressed() -> void:
	$No2.visible = false


func _on_continue_3_pressed() -> void:
	$No3.visible = false


func _on_continue_4_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
