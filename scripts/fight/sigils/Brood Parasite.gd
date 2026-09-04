extends Sigil


func egg_data() -> Ruleset.CardData:
	var raven_egg := get_config("good_egg_card", "Raven Egg") as String
	var broken_egg := get_config("bad_egg_card", "Broken Egg") as String
	if raven_egg.is_empty():
		return Global.get_card_by_name(broken_egg) 
		
	else: 
		if randf() < get_config("bad_egg_rng", 0.9) as float: 
			return Global.get_card_by_name(broken_egg as String) 
			
		else:
			return Global.get_card_by_name(raven_egg as String) 
	
	
func on_card_played(
	played_card: Card, pos: Vector2i, _placer_type: Action.IDType, _placer_id: String
) -> void:
	if played_card != attached_card:
		return
		
	create_and_play_token(egg_data(), oppose_pos(pos))
