extends Sigil


func cards_drawn() -> int:
	return get_config("handy_cards_drawn", 4) as int


func on_card_played(
	card: Card, pos: Vector2i, placer_type: Action.IDType, placer_id: String
) -> void:
	if card != attached_card:
		return
	
	var cont_id : String = controller_id()
	
	if cont_id == Global.uuid:
		for handcard in fight_manager.card_manager.get_cards_by_zone(Card.Zone.HAND):
			discard_card(cont_id, handcard.id)
	else:
		for i in range(fight_manager.opp_data.hand_size):
			discard_card(cont_id, "")
	draw_cards(DrawCardAction.Deck.MAIN, cards_drawn(), controller_id())
