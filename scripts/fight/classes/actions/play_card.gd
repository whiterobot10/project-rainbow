class_name PlayCardAction
extends Action

# This class also serves as an example with documentation if you want to implement a new action

# You should provide a description for the action, better if you also include the field that it have
# and what they mean/do.
## This action represent the playing of a card with [member card_id] at [member pos] by
## [method placer_id] which is a [member placer_type]

# Define here any data your action might hold
var card_id: String
var pos: Vector2i
var placer_type: IDType
var placer_id: String


# This is the unique action type that you define in Action.Type
static func action_type() -> Type:
	return Type.PLAY_CARD


# A constructor for this action so we can make them
func _init(c: String, p: Vector2i, pt: IDType, pi: String) -> void:
	card_id = c
	pos = p
	placer_type = pt
	placer_id = pi


# Resolver for this sigil action, the fight manager is the copy of the current fight manager
func resolve(fight_manager: FightManager) -> void:
	if not fight_manager.board_manager.is_slot_empty(pos):
		push_warning("Nuh uh no playing into non empty slot >:(")
		# Always call some sort of sigil activation function event if there are no sigil hook.
		# If you don't include this your stack will stall indefinitely.
		fight_manager._no_activation()
		return

	fight_manager.card_manager.move_card(card_id, Card.Zone.BOARD)
	var slot := fight_manager.board_manager.get_slot(pos)
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	slot.card = card
	card.z_index = 0

	if placer_type == Action.IDType.PLAYER:
		var data := fight_manager.get_data(placer_id)
		data.hand_size -= 1
		var t := data.public_card.find_custom(func(c: Card) -> bool: return c.id == card_id)
		if t != -1:
			data.public_card.remove_at(t)

	# Always call some sort of sigil activation function event if there are no sigil hook.
	# in that case you can use fight_manager._no_activation() as the activation. If you don't
	# include this your stack will stall indefinitely.
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_card_played(card, pos, placer_type, placer_id)
	)


# Because playing a card can be trigger manually by the player, implement al the serialization
# method


func as_dict() -> Dictionary:
	var opos := BoardManager.oppose_pos(pos)
	return {
		type = action_type(),
		card_id = card_id,
		pos = {x = opos.x, y = opos.y},
		placer_type = placer_type,
		placer_id = placer_id
	}


func duplicate() -> Action:
	return PlayCardAction.new(card_id, pos, placer_type, placer_id)


static func from_dict(dict: Dictionary) -> Action:
	return PlayCardAction.new(
		dict.card_id as String,
		Vector2i(dict.pos.x as int, dict.pos.y as int),
		dict.placer_type as IDType,
		dict.placer_id as String
	)
