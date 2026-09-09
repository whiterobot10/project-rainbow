extends Sigil


func on_any_action_resolved(_type: Action.Type, _act: Action) -> void:
	if attached_card.zone != Card.Zone.BOARD:
		return
	var moxes: Card.Costs.Mox = fight_manager.get_moxes()
	if moxes.green <= 0 and moxes.orange <= 0 and moxes.blue <= 0:
		kill_card(attached_card.id)
