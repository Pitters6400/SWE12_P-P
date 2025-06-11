extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_god_mode_pressed() -> void:
	Global.godmode = true



func _on_all_dragons_pressed() -> void:
	Global.starting_deck.clear()
	for i in range(50):
		Global.starting_deck.append("dragon") 




func _on_inf_money_pressed() -> void:
	Global.total_money = 1000



func _on_main_menu_pressed() -> void:
	Transition.load_scene("res://Scenes/main_menu.tscn")
