extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disable()

func disable():
	$"Card Info/Dragon".visible = false
	$"Card Info/Wizard".visible = false
	$"Card Info/Knight".visible = false
	$"Card Info/Goblin".visible = false
	$"Card Info/Tornado".visible = false

func _on_dragon_pressed() -> void:
	disable()
	$"Card Info/Dragon".visible = true

func _on_wizard_pressed() -> void:
	disable()
	$"Card Info/Wizard".visible = true

func _on_knight_pressed() -> void:
	disable()
	$"Card Info/Knight".visible = true

func _on_goblin_pressed() -> void:
	disable()
	$"Card Info/Goblin".visible = true

func _on_tornado_pressed() -> void:
	disable()
	$"Card Info/Tornado".visible = true

func _on_return_to_levels_pressed() -> void:
	Transition.load_scene("res://Scenes/levels.tscn")
