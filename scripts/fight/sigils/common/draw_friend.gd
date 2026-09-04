@abstract class_name DrawFriendSigil
extends Sigil

## Return the data that is used to draw the friend.
@abstract func friend_data() -> Ruleset.CardData


func on_card_played(
	card: Card, _pos: Vector2i, _placer_type: Action.IDType, _placer_id: String
) -> void:
	if card != attached_card:
		return
	create_and_add_token(friend_data(), controller_id(), card.id)
