extends SpecialAttack


func attack_value() -> int:
	var row := BoardManager.Row.MINE if controller_id() == Global.uuid else BoardManager.Row.OPP
	return (
		fight_manager
		. board_manager
		. get_row(row)
		. filter(func(s: BoardManager.Slot) -> bool: return not s.is_empty())
		. filter(func(s: BoardManager.Slot) -> bool: return "Green Mox" in s.card.sigils)
		. size()
	)
