extends Sigil


func detonation_damage() -> int:
	return get_config("detonation_damage", 5) as int


func on_card_perished(card: Card) -> void:
	if card != attached_card:
		return
	var pos := get_pos()
	var adjacent_slots: Array[BoardManager.Slot]
	var t := [
		fight_manager.board_manager.get_slot(pos + Vector2i.LEFT),
		fight_manager.board_manager.get_slot(oppose_pos(pos)),
		fight_manager.board_manager.get_slot(pos + Vector2i.RIGHT)
	]
	adjacent_slots.assign(t.filter(func(s: BoardManager.Slot) -> bool: return s != null))
	
	for slot in adjacent_slots:
		if slot.is_empty():
			continue
		damage_card(slot.card.id, detonation_damage(), Action.IDType.CARD, card.id)
