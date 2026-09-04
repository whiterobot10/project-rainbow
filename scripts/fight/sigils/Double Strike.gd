extends Sigil


func on_card_attacked(card: Card) -> Array[CardAttackAction.StrikeGroup]:
	if card != attached_card:
		return []
	var pos := oppose_pos(get_pos(card.id))
	return [
	CardAttackAction.StrikeGroup.new(pos).add_strike(card.id).add_strike(card.id)
	]
