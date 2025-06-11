extends Node2D

# Collision mask constants for raycasting
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

# Default speeds and scales for card movement and display
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1
const CARD_BIGGER_SCALE = 1.2
const CARD_SMALLER_SCALE = 1

# Variables to store screen size, current dragged card, hover state, reference to player hand, 
# and whether a monster card has been played this turn or a monster card is selected
var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var played_monster_card_this_turn = false
var selected_monster

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../BattleMusic".play()  # Play battle music on scene start
	screen_size = get_viewport_rect().size  # Get size of the game viewport
	player_hand_reference = $"../PlayerHand"  # Reference to the player's hand node
	# Connect input manager signal for mouse release to the handler function
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If a card is being dragged, update its position to follow the mouse, clamped to screen bounds
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))


# Called when a card is clicked by the player
func card_clicked(card):
	# If card is already in a card slot on battlefield
	if card.card_slot_card_is_in:
		# Ignore clicks during opponent's turn
		if $"../BattleManager".is_opponents_turn:
			return
		
		# Only allow "Monster" type cards to be selected for battle
		if card.card_type != "Monster":
			return
		
		# Prevent selecting cards that have already attacked this turn
		if card in $"../BattleManager".player_cards_that_attacked_this_turn:
			return
		
		# If opponent has no cards on battlefield, perform direct attack
		if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
			$"../BattleManager".direct_attack(card, "Player")
		else:
			# Otherwise, select this card for battle actions
			select_card_for_battle(card)
	else:
		# If card is not on battlefield, start dragging it
		start_drag(card)


# Select or toggle selection of a monster card for battle
func select_card_for_battle(card):
	# Check if a monster is already selected
	if selected_monster:
		# If the same card is selected again, deselect it by moving it down
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			# If different card selected, move old selection down and new selection up
			selected_monster.position.y += 20
			selected_monster = card
			card.position.y -= 20
	else:
		# No card previously selected, select this one and move it up visually
		selected_monster = card
		card.position.y -= 20


# Begin dragging a card (e.g., from hand)
func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)  # Reset scale to default when dragging


# Called to finish dragging a card (when mouse released)
func finish_drag():
	card_being_dragged.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)  # Scale card up while placing
	var card_slot_found = raycast_check_for_card_slot()  # Check if dropped over a card slot
	if card_slot_found and not card_slot_found.card_in_slot:
		# Card dropped on an empty card slot
		# Check if the card type matches the slot type (e.g., Monster card on Monster slot)
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			# If it's a monster card, check if already played monster this turn
			if card_being_dragged.card_type == "Monster":
				if played_monster_card_this_turn:
					# If already played a monster this turn, return card to hand
					player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
					card_being_dragged = null
					return
			
			# Place card into slot
			card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)  # Scale card down
			card_being_dragged.z_index = -1  # Send card behind other UI elements
			is_hovering_on_card = false
			card_being_dragged.card_slot_card_is_in = card_slot_found  # Link card to slot
			player_hand_reference.remove_card_from_hand(card_being_dragged)  # Remove card from hand display
			card_being_dragged.position = card_slot_found.position  # Snap card to slot position
			card_slot_found.card_in_slot = true  # Mark slot as occupied
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true  # Disable slot's collision
			
			# If monster card, add to battlefield list and mark that a monster was played this turn
			if card_being_dragged.card_type == "Monster":
				$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
				played_monster_card_this_turn = true
			
			# If card has an ability script, trigger ability for placing card
			if card_being_dragged.ability_script:
				card_being_dragged.ability_script.trigger_ability($"../BattleManager", card_being_dragged, $"../InputManager", "card_placed")
			
			card_being_dragged = null
			return
	# If no valid slot found or other conditions failed, return card to hand
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null


# Deselect currently selected monster, moving it back visually
func unselect_selected_monster():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null


# Connect hover signals for a card to input manager handlers
func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)


# Handler for when left mouse button is released
func on_left_click_released():
	if card_being_dragged:
		finish_drag()


# Called when mouse hovers over a card
func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)  # Highlight card on hover


# Called when mouse stops hovering over a card
func on_hovered_off_card(card):
	if !card.defeated:
		# If card is not in a slot and no card is being dragged
		if !card.card_slot_card_is_in && !card_being_dragged:
			highlight_card(card, false)  # Remove highlight
			# Check if hovering directly onto another card and highlight it if found
			var new_card_hovered = raycast_check_for_card()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false


# Changes card scale and z-index for hover highlight effect
func highlight_card(card, hovered):
	if !card.card_slot_card_is_in:
		if hovered:
			card.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
			card.z_index = 2
		else:
			card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
			card.z_index = 1


# Raycast to check if mouse is over a card slot
func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT  # Only detect card slots
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


# Raycast to check if mouse is over a card
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD  # Only detect cards
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)  # Return topmost card under mouse
	return null


# From a list of cards hit by raycast, get the card with highest z-index (topmost visually)
func get_card_with_highest_z_index(cards):
	# Assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


# Reset flag allowing player to play a monster card again next turn
func reset_played_monster():
	played_monster_card_this_turn = false
