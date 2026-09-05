class_name DiscardCardAction
extends Action

var player_id: String
var card_id: String


static func action_type() -> Type:
	return Action.Type.DISCARD_CARD


func _init(
	pid: String,
	cid: String,
) -> void:
	player_id = pid
	card_id = cid


func resolve(fight_manager: FightManager) -> void:
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	if card == null and player_id != Global.uuid:
		# if it is null assume the card is valid on the other end and just add it to the hand
		fight_manager.opp_data.hand_size -= 1
		await fight_manager._activate_hooks(
			func(hook: ActionHook) -> void: hook.on_card_discarded(card, player_id)
		)
		return
	if card == null:
		# Uh oh shit it the fan this time
		push_warning("Can't resolve card to discard")
		fight_manager._no_activation()
		return
	var data := fight_manager.get_data(player_id)
	data.hand_size -= 1
	fight_manager.card_manager.move_card(
		card_id, Card.Zone.GRAVEYARD
	)
	if player_id != Global.uuid:
		card.visible = false

	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_card_discarded(card, player_id)
	)


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id, card_id = card_id}


static func from_dict(dict: Dictionary) -> Action:
	return (
		AddCardAction
		. new(
			dict.player_id as String,
			dict.card_id as String,
		)
	)
