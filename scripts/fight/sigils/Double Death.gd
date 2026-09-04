extends Sigil

## ID of card that already trigger double death so they don't do that again.
var already_die: Array[String] = []


func on_card_perished(card: Card) -> void:
	
	if card == attached_card:
		return
	
	if (
		card.id in already_die
		or (
			fight_manager.board_manager.get_card_pos(attached_card.id).y
			!= fight_manager.board_manager.get_card_pos(card.id).y
		)
	):
		return
	already_die.append(card.id)
	play_card(
		card.id,
		fight_manager.board_manager.get_card_pos(card.id),
		Action.IDType.CARD,
		attached_card.id
	)
	kill_card(card.id)
