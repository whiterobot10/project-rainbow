class_name ChangeStatsAction
extends Action


## This action represent giving a card with [member card_id] an attack buff equal to [member power] and a heal equal to [member health].
## This can heal a card beyond it's base health as determiend by card data.




## The id of the card gaining permanent stats
var card_id: String
## The amount of permanent attack the card is gaining
var attack: int
## There are two types of people in the world; those that can extrapolate from incomplete data...
var health: int


static func action_type() -> Type:
	return Type.CHANGE_STATS


func _init(cid: String, a: int, h: int) -> void:
	card_id = cid
	attack = a;
	health = h;


func resolve(fight_manager: FightManager) -> void:
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	if card == null:
		push_warning("They're dead. You can't change their stats if they're dead.")
		@warning_ignore("redundant_await")
		await fight_manager._no_activation()
		return
		
	card.attack_buf += attack
	card.health += health

	await fight_manager._activate_sigils(
		func(sigil: Sigil) -> void: sigil.on_card_changed_stats(card, attack, health)
	)
	if card.health <= 0:
		fight_manager._push_action(KillCardAction.new(card_id))




func as_dict() -> Dictionary:
	return {
		type = action_type(),
		card_id = card_id,
		attack = attack,
		health = health
	}



static func from_dict(dict: Dictionary) -> Action:
	return ChangeStatsAction.new(
		dict.card_id as String,
		dict.attack as int,
		dict.health as int
	)
