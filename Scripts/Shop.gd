extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var eye = $Eyes

var money
var dialogue_lines = []
var current_line = 0
var card_tracker = 0
var displayed_text = ""
var full_text = ""
var char_index = 0
var typing_speed = 0.05
var typing_timer = 0.0
var is_typing = false

var card_database_reference
var cards_dict = {}
var card_names = []

var bob_amount := 5.0
var bob_duration := 1.0
var tween: Tween = null

var animation_finished_displayed := false


func _ready():
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	cards_dict = card_database_reference.CARDS
	card_names = cards_dict.keys()
	print(Global.starting_deck)
	
	start_eye_bob()
	money = Global.total_money
	$GoldTracker.text = str(money)

	start_dialogue([
		"Care to see my wares",
		"You can buy powerful cards here."
	])


func _enter_tree() -> void:
	$GoldTracker.text = str(Global.total_money)


func _on_card_shop_slot_pressed() -> void:
	if card_tracker >= 3:
		$CardShopSlot.disabled = true
		$CardShopSlot.visible = false
		return  # Stop any more purchases

	if money < 10:
		print("You don’t have enough money.")
		return  # Can't buy, so stop here

	# Purchase successful
	money -= 10
	Global.total_money = money
	card_tracker += 1
	Global.starting_deck.append("dragon") 
	$GoldTracker.text = str(money)

	if card_tracker >= 3:
		$CardShopSlot.disabled = true
		$CardShopSlot.visible = false
	money -= 10
	Global.total_money = money
	Global.starting_deck.append("dragon")
	$GoldTracker.text = str(money)


func _on_button_pressed() -> void:
	Transition.load_scene("res://Scenes/levels.tscn")


func start_dialogue(lines: Array):
	dialogue_lines = lines
	current_line = 0
	$TextBox.show()
	_start_typing_line()


func _start_typing_line():
	full_text = dialogue_lines[current_line]
	displayed_text = ""
	char_index = 0
	typing_timer = 0.0
	is_typing = true
	$TextBox/MarginContainer/HBoxContainer/Text.text = ""


func _process(delta):
	if is_typing:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			if char_index < full_text.length():
				displayed_text += full_text[char_index]
				char_index += 1
				$TextBox/MarginContainer/HBoxContainer/Text.text = displayed_text
			else:
				is_typing = false


func _input(event):
	if $TextBox.visible and event.is_action_pressed("ui_accept"):
		if is_typing:
			displayed_text = full_text
			$TextBox/MarginContainer/HBoxContainer/Text.text = displayed_text
			is_typing = false
		else:
			current_line += 1
			if current_line < dialogue_lines.size():
				_start_typing_line()
			else:
				$TextBox.hide()


func start_eye_bob() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(eye, "position:y", eye.position.y - bob_amount, bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(eye, "position:y", eye.position.y, bob_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "start_eye_bob"))


func _on_pack_button_pressed() -> void:
	if money < 20:
		print("You don’t have enough money.")
		return
	
	money -= 10
	Global.total_money = money
	$GoldTracker.text = str(money)
	
	animation_player.play("TearAnimation")
	$PackButton.visible = false
	$PackButton.disabled = true
	display_received_cards_message()

	
	animation_finished_displayed = false  # Reset for next animation
	print(Global.starting_deck)


func display_received_cards_message() -> void:
	var selected_cards = card_names.duplicate()
	selected_cards.shuffle()
	selected_cards = selected_cards.slice(0, min(3, selected_cards.size()))

	# Add the selected cards to the player's deck here
	for card_name in selected_cards:
		Global.starting_deck.append(card_name)
	print("Current deck:", Global.starting_deck)

	# Now build the message
	var message := "You received a "
	if selected_cards.size() == 1:
		message += selected_cards[0]
	elif selected_cards.size() == 2:
		message += selected_cards[0] + " and " + selected_cards[1]
	else:
		var all_but_last_array = selected_cards.slice(0, selected_cards.size() - 1)
		var all_but_last = ""
		for i in range(all_but_last_array.size()):
			all_but_last += all_but_last_array[i]
			if i < all_but_last_array.size() - 1:
				all_but_last += ", "
		message += all_but_last + " and " + selected_cards[-1]

	$PackLabel.text = message
