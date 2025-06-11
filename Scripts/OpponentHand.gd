extends Node2D

const CARD_WIDTH = 160
const HAND_Y_POSITION = -30
const DEFAULT_CARD_MOVE_SPEED = 0.1

var opponent_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


func add_card_to_hand(card, speed):
	if card not in opponent_hand:
		opponent_hand.insert(0, card)
		update_hand_positions(speed)
		scale_card_up(card, speed)  # Scale up the card when it leaves the hand
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)



func update_hand_positions(speed):
	for i in range(opponent_hand.size()):
		# Get new card position based on index
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = opponent_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position, speed)

# Function to scale up the card before it leaves the hand
func scale_card_up(card, speed):
	# Create the tween and scale the card up
	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", Vector2(1.2, 1.2), speed)  # Scale up
	animate_card_to_position(card, card.starting_position, speed)



func calculate_card_position(index):
	var total_width = (opponent_hand.size() -1) * CARD_WIDTH
	var x_offset = center_screen_x - index * CARD_WIDTH + total_width / 2
	return x_offset


func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)


func remove_card_from_hand(card):
	if card in opponent_hand:
		opponent_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
		$"../AudioClickPlayer".play()
