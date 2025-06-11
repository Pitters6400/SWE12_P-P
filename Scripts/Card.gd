extends Node2D

signal hovered
signal hovered_off

const CARD_SCALE = 1

var starting_position
var card_slot_card_is_in
var ability_script # Set when card is instantiated and will be null if no ability
var card_type
var health
var attack
var defeated = false
