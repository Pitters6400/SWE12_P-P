extends Node

# Constants for movement speed, starting health, and position offset in battle animations
const MOVE_SPEED = 0.2
const STARTING_HEALTH = 10
const BATTLE_POS_OFFSET = 25

# Variables to keep track of battle state
var battle_timer                             # Timer for managing battle delays
var empty_monster_card_slots = []           # List of empty slots where opponent can place monsters
var opponent_cards_on_battlefield = []      # Opponent's cards currently on the battlefield
var player_cards_on_battlefield = []        # Player's cards currently on the battlefield
var player_cards_that_attacked_this_turn = [] # Player cards that have attacked this turn
var player_health                           # Player's current health
var opponent_health                         # Opponent's current health
var is_opponents_turn = false               # Flag to track if it's opponent's turn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set player health based on godmode or default starting health
	if Global.godmode:
		player_health = 100
	else:
		player_health = STARTING_HEALTH
	
	# Set opponent health; higher if boss fight
	if Global.boss == true:
		opponent_health = 25
		$"../BossHue".visible = true   # Show boss visual effect
	else:
		opponent_health = STARTING_HEALTH
	
	# Update health UI text
	$"../PlayerHealth".text = str(player_health)
	$"../OpponentHealth".text = str(opponent_health)

	# Initialize the battle timer node, set it as one-shot and 1 second wait
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0

	# Add opponent card slots to the empty slots list for card placement
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot1")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot2")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot3")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot4")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot5")

	# Check if game has been won or lost at start
	check_win_conditions()

	# Update health UI text again (redundant here but called twice)
	$"../PlayerHealth".text = str(player_health)
	$"../OpponentHealth".text = str(opponent_health)
	check_win_conditions()


# Function to deal direct damage to opponent, update health and UI
func direct_damage(damage):
	opponent_health = max(0, opponent_health - damage)
	$"../OpponentHealth".text = str(opponent_health)


# Called when the player presses the end turn button
func _on_end_turn_button_pressed() -> void:
	is_opponents_turn = true                          # Switch turn to opponent
	$"../CardManager".unselect_selected_monster()     # Deselect any selected player monster

	# Reset abilities of all player cards that attacked this turn
	for card in player_cards_that_attacked_this_turn:
		if card.ability_script:
			card.ability_script.end_turn_reset()
	
	player_cards_that_attacked_this_turn = []       # Clear list for new turn
	
	opponent_turn()                                  # Start opponent's turn


# Enable or disable the end turn button based on boolean parameter
func end_turn_button_enabled(is_enabled):
	if is_enabled:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false


# The opponent's turn logic (async to allow for waits/animations)
func opponent_turn():
	$"../EndTurnButton".disabled = true       # Disable end turn button during opponent turn
	$"../EndTurnButton".visible = false
	
	await wait(1.0)                            # Pause for 1 second before actions
	
	# Opponent draws a card if their deck is not empty
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		await wait(1.0)                        # Wait after drawing
	
	# If there is any empty monster slot, try to play the highest attack card
	if empty_monster_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
	
	# If opponent has cards on battlefield, perform attacks
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate() # Copy array to loop safely
		for card in enemy_cards_to_attack:
			# If player has cards on battlefield, attack random player card
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Opponent")
			else:
				# Otherwise, attack player directly
				await direct_attack(card, "Opponent")
	
	# End opponent turn after attacks
	end_opponent_turn()


# Animate and handle direct attack on player or opponent when no defending card
func direct_attack(attacking_card, attacker):
	$"../DirectHitSound".play()                 # Play direct hit sound
	var new_pos_y
	
	if attacker == "Opponent":
		new_pos_y = 1080                        # Position offscreen (bottom) for opponent attack animation
	else:
		$"../InputManager".inputs_disabled = true  # Disable player inputs during attack
		end_turn_button_enabled(false)              # Disable end turn button
		new_pos_y = 0                               # Position offscreen (top) for player attack animation
		player_cards_that_attacked_this_turn.append(attacking_card)  # Mark card as attacked
	
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)  # Target position for attack animation
	
	attacking_card.z_index = 5                    # Bring card visually in front
	
	# Tween card to new position with speed
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, MOVE_SPEED)
	await wait(0.15)                              # Wait for partial animation
	
	# Apply damage to health and update UI depending on attacker
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
	else:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		$"../OpponentHealth".text = str(opponent_health)
	
	# Tween card back to its original slot position
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, MOVE_SPEED)
	
	attacking_card.z_index = 0                     # Reset z_index
	await wait(1.0)                                # Wait after attack
	
	if attacker == "Player":
		# Trigger card ability after attack if exists
		if attacking_card.ability_script:
			await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
		$"../InputManager".inputs_disabled = false    # Re-enable inputs
		end_turn_button_enabled(true)                  # Enable end turn button again
	
	check_win_conditions()                           # Check if game ended


# Handle attacking card vs defending card battle interaction
func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		$"../InputManager".inputs_disabled = true   # Disable player input during attack animation
		end_turn_button_enabled(false)               # Disable end turn button
		$"../CardManager".selected_monster = null   # Deselect attacking monster
		player_cards_that_attacked_this_turn.append(attacking_card)  # Mark card as attacked
	
	attacking_card.z_index = 5                      # Bring attacking card to front
	
	# Tween attacking card to position slightly above defending card
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, MOVE_SPEED)
	await wait(0.15)
	
	# Tween attacking card back to its original slot
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, MOVE_SPEED)
	
	# Cards deal damage to each other simultaneously
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	$"../DamageSound".play()                      # Play damage sound
	
	await wait(1.0)                                # Wait after damage exchange
	attacking_card.z_index = 0                      # Reset z_index
	
	var card_was_destroyed = false
	# Destroy cards if health reaches zero
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		card_was_destroyed = true
	
	if card_was_destroyed:
		await wait(1.0)                            # Wait after destruction
	
	if attacker == "Player":
		# Trigger ability if any after attack
		if attacking_card.ability_script:
			await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
		$"../InputManager".inputs_disabled = false   # Re-enable player input
		end_turn_button_enabled(true)                 # Enable end turn button again


# Handles removing a card from battlefield and animating it to discard pile
func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		card.get_node("Area2D/CollisionShape2D").disabled = true   # Disable collision on card
		new_pos = $"../PlayerDiscard".position                       # Target position is player discard pile
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)                  # Remove from player battlefield list
		card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false # Enable slot collision again
	else:
		new_pos = $"../OpponentDiscard".position                     # Opponent discard pile position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)                # Remove from opponent battlefield list
	
	card.card_slot_card_is_in.card_in_slot = false                  # Mark slot as empty
	card.card_slot_card_is_in = null                                # Remove reference to slot
	
	var tween = get_tree().create_tween()                           # Tween card to discard pile
	$"../DeathSound".play()                                         # Play death sound
	tween.tween_property(card, "position", new_pos, MOVE_SPEED)


# Called when an enemy card is selected by the player to attack
func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster    # Get player's selected attacking monster
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			$"../CardManager".selected_monster = null          # Deselect after attack
			attack(attacking_card, defending_card, "Player")   # Perform attack


# Try to play the card with highest attack from opponent's hand to battlefield
func try_play_card_with_highest_attack():
	# Get opponent's hand cards
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()   # No cards to play, end opponent turn
		return
	
	# Pick a random empty monster slot for placement
	var random_empty_monster_card_slot = empty_monster_card_slots.pick_random()
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	
	# Find the card with highest attack in opponent's hand
	var card_with_highest_atk = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > card_with_highest_atk.attack:
			card_with_highest_atk = card
	
	# Animate card moving to the chosen empty slot and scaling up
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, MOVE_SPEED)
	var scale_tween = get_tree().create_tween()
	scale_tween.tween_property(card_with_highest_atk, "scale", Vector2(1, 1), MOVE_SPEED)

	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")  # Play card flip animation
	
	$"../OpponentHand".remove_card_from_hand(card_with_highest_atk)    # Remove from hand list
	card_with_highest_atk.card_slot_card_is_in = random_empty_monster_card_slot  # Set card slot reference
	opponent_cards_on_battlefield.append(card_with_highest_atk)        # Add to battlefield
	
	await wait(1.0)    # Wait for animation to complete


# Utility function to await a timer for delays
func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout


# Check if either player or opponent health <= 0 and trigger win/lose condition
func check_win_conditions():
	if int(player_health) <= 0:
		print("You lose")
		Global.total_money -= 5                  # Penalize money on loss
		print(Global.total_money)
		Transition.load_scene("res://Scenes/levels.tscn")  # Go back to level select
	elif int(opponent_health) <= 0:
		print("You win")
		Global.total_money += 10                 # Reward money on win
		print(Global.total_money)
		Transition.load_scene("res://Scenes/levels.tscn")  # Go back to level select


# End the opponent's turn, reset draw and states
func end_opponent_turn():
	$"../Deck".reset_draw()                   # Reset deck draw status
	$"../CardManager".reset_played_monster() # Reset played monster selection/state
	is_opponents_turn = false                 # Switch turn back to player
	$"../EndTurnButton".disabled = false     # Enable end turn button for player
	$"../EndTurnButton".visible = true


# Function to change scene to shop - possibly unused here
func change_to_battle():
	Transition.load_scene("res://Scenes/Shop.tscn")
