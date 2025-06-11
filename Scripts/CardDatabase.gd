
const CARDS = { # Attack, Health, Card type, Ability script, Ability text
	"knight" : [2, 5, "Monster", null, null],
	"wizard" : [4, 6, "Monster", null, null],
	"goblin" : [1, 5, "Monster", "res://Scripts/Abilities/Arrow.gd", "Deal 1 damage to opponent when played."],
	"dragon" : [4, 10, "Monster", "res://Scripts/Abilities/AttackTwice.gd", "If this card attacks, it can attack once again."],
	"Tornado" : [null, null, "Magic", "res://Scripts/Abilities/Tornado.gd", "Deal 1 damage to all opponent cards."]
}
