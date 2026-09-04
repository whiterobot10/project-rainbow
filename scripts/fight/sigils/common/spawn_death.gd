@abstract class_name SpawnDeathSigil
extends Sigil

## Return the data that is used to spawn the new form.
@abstract func new_form() -> Ruleset.CardData


func on_card_perished(card: Card) -> void:
	if card != attached_card:
		return
	create_and_play_token(new_form(), get_pos())
