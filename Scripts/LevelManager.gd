extends Control

func _draw() -> void:
	$GoldTracker.text = str(Global.total_money)



func _ready():
	disable_all()
	if Global.game_tracker == 1:
		enable_lvl1()
	elif Global.game_tracker == 2:
		enable_lvl2()
	elif Global.game_tracker == 3:
		enable_lvl3()
	elif Global.game_tracker == 4:
		enable_lvl4()

	for button in get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_level_pressed").bind(button.name))

func disable_all():
	$HBoxContainer/LVL1.disabled = true
	$HBoxContainer/LVL2.disabled = true
	$HBoxContainer/LVL3.disabled = true
	$HBoxContainer/LVL4.disabled = true

func enable_lvl1():
	$HBoxContainer/LVL1.disabled = false

func enable_lvl2():
	$HBoxContainer/LVL2.disabled = false

func enable_lvl3():
	$HBoxContainer/LVL3.disabled = false

func enable_lvl4():
	$HBoxContainer/LVL4.disabled = false

func _on_lvl_1_pressed() -> void:
	enable_lvl1()
	Global.game_tracker += 1
	call_deferred("_change_scene")
	Transition.load_scene("res://Scenes/battle.tscn")

func _on_lvl_2_pressed() -> void:
	enable_lvl2()
	Global.game_tracker += 1
	if Global.get_num1() == 1:
		Transition.load_scene("res://Scenes/battle.tscn")
	else:
		Transition.load_scene("res://Scenes/Shop.tscn")

func _on_lvl_3_pressed() -> void:
	enable_lvl3()
	Global.game_tracker += 1
	if Global.get_num2() == 1:
		Transition.load_scene("res://Scenes/battle.tscn")
	else:
		Transition.load_scene("res://Scenes/Shop.tscn")

func _on_lvl_4_pressed() -> void:
	enable_lvl4()
	Global.game_tracker += 1
	if Global.get_num3() == 1:
		Transition.load_scene("res://Scenes/battle.tscn")
	else:
		Transition.load_scene("res://Scenes/Shop.tscn")


func _on_lvl_5_pressed() -> void:
	Global.boss = true
	$Journal.visible = false
	$BossSkull/AnimationPlayer.play("Skull_Eat")
	await get_tree().create_timer(2.5).timeout
	Transition.load_scene("res://Scenes/battle.tscn")


func _on_level_pressed(level_name: String) -> void:
	if level_name == "LVL1":
		_on_lvl_1_pressed()
	elif level_name == "LVL2":
		_on_lvl_2_pressed()
	elif level_name == "LVL3":
		_on_lvl_3_pressed()
	elif level_name == "LVL4":
		_on_lvl_4_pressed()
	else:
		print("Unknown button pressed: ", level_name)


func _on_journal_pressed() -> void:
	Transition.load_scene("res://Scenes/journal.tscn")
