extends Sigil


func on_card_played(
	played_card: Card, pos: Vector2i, _placer_type: Action.IDType, _placer_id: String
) -> void:
	if played_card == attached_card:
		return
		 
	if get_pos().y != pos.y:
		return
	
	flip_h = get_pos().x > pos.x
	
	var direction := Vector2i.RIGHT if get_pos().x > pos.x else Vector2i.LEFT
	
	#This checks to the left or right of the played card
	for slot in fight_manager.board_manager.get_active_row(true):
		pos += direction
		
		# Safety Break, so it doesn't go backwards
		if pos == get_pos():
			break
		
		#checks for the closest empty space
		elif fight_manager.board_manager.is_slot_empty(pos):
			move_card(attached_card.id, pos)
			break
