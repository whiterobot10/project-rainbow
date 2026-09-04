@abstract class_name Sigil
extends ActionHook

## Most method in this class create an action that is appended to the internal stack of this sigil.
## They are promises that this will happens.

## The fight manager that is current "active".
## Just a reference to the fightmanager so you can access like the board, hand,
## play card and general utils offer by the fight manager.
var fight_manager: FightManager
## The card this sigil is attached to.
var attached_card: Card

var _stack: Array[Action]

# --- Sigil non event hook ---

func blood_value() -> int:
	return 0


func mox_value() -> Card.Costs.Mox:
	return Card.Costs.Mox.new()


func activate_in_hand() -> bool:
	return false


func is_active_sigil() -> bool:
	return false


## Disable the active sigil. This function get run every frame to see if a active should still be
## enable.
func is_disable() -> bool:
	return false


## Wherever the active sigil can be activate by anyone.
func is_universal() -> bool:
	return false


@warning_ignore_start("unused_parameter")  # keep the signature clean while avoiding warning


## Static ability that is ran when sigil suppose to activate usually after the event hook. It is
## called for the first time with [param is_reset] set to [code]true[/code], meant for the sigil to
## reset the state or whatever, then it is called a second time with [param is_reset] set to
## [code]false[/code], to actually put the static ability in action again. Unlike normal event hook,
## this function should not modify the stack as it does nothing but instead modify the game state
## directly.
func static_ability(is_reset: bool) -> void:
	pass


## Called whenever an action is added to the stack. If this return a non empty array the top action
## of the stack is replace with the returned value.
## Unless it is absolutely necessary don't use this hook.
func replace_action(type: Action.Type, act: Action) -> Array[Action]:
	return []

## Called after [CardAttackAction] resolved. This will dictate what [CardStrikeAction] the card will
## do whatever strike group this function spit out. If by the end of all the strike sigils activation
## the card still have no [StrikeGroup] the default center strike is issued.
func on_card_attacked(card: Card) -> Array[CardAttackAction.StrikeGroup]:
	return []

@warning_ignore_restore("unused_parameter")


# --- Helper function and utils ---


func add_action(action: Action) -> void:
	_stack.push_front(action)


## Play [param card_id] at [param pos] by [param placer_id] which is a [param placer_type]
func play_card(
	card_id: String, pos: Vector2i, placer_type: Action.IDType, placer_id: String
) -> void:
	add_action(PlayCardAction.new(card_id, pos, placer_type, placer_id))


## Create a new token with [param card_data] by [param source_id]. Return the new token's id[br]
func create_token(card_data: Ruleset.CardData, source_id: String) -> String:
	var token_id := Global.gen_id()
	add_action(CreateTokenAction.new(card_data, token_id, source_id))
	return token_id


## Create a new token with [param card_data] by [param source_id] and play it at [param pos].
## [source_id] default to [attached_card]'s id.[br]
## Return the new token's id.
func create_and_play_token(card_data: Ruleset.CardData, pos: Vector2i, source_id := "") -> String:
	if source_id.is_empty():
		source_id = attached_card.id
	var id := create_token(card_data, source_id)
	play_card(id, pos, Action.IDType.CARD, source_id)
	return id


func move_card(card_id: String, to_pos: Vector2i) -> void:
	add_action(MoveCardAction.new(card_id, to_pos))


func transform_card(card_id: String, card_data: Ruleset.CardData) -> void:
	add_action(TransformCardAction.new(card_id, card_data))


func change_stats(card_id: String, add_power: int, add_health: int) -> void:
	add_action(ChangeStatsAction.new(card_id, add_power, add_health))


func kill_card(card_id: String) -> void:
	add_action(KillCardAction.new(card_id))


func damage_card(
	victim_id: String, amount: int, attacker_type: Action.IDType, attacker_id: String
) -> void:
	add_action(DamageCard.new(victim_id, amount, attacker_type, attacker_id))


func draw_card(deck: DrawCardAction.Deck, player_id := "") -> void:
	if player_id.is_empty():
		player_id = controller_id()
	add_action(DrawCardAction.new(deck, player_id))


func draw_cards(deck: DrawCardAction.Deck, amount: int, player_id := "") -> void:
	for i in amount:
		draw_card(deck, player_id)


## Add a new card to the [param player_id]'s hand with id [param card_id]
func add_card(player_id: String, card_id: String) -> String:
	add_action(AddCardAction.new(player_id, card_id))
	return card_id


## Create a new token and add it to [param player_id]'s hand with id [param card_data].
## [param player_id] default to [method controller_id], [param source_id] default to
## [member attached_card]'s id.[br]
## Return the new token's id.
func create_and_add_token(card_data: Ruleset.CardData, player_id := "", source_id := "") -> String:
	if player_id.is_empty():
		player_id = controller_id()
	if source_id.is_empty():
		source_id = attached_card.id
	var id := create_token(card_data, source_id)
	add_card(player_id, id)
	return id


func change_bone(amount: int, player_id: String, death_source_id := "") -> void:
	add_action(ChangeBonesAction.new(amount, player_id, death_source_id))
	
func change_cells(amount: int, player_id: String, is_empty: bool = false) -> void:
	add_action(ChangeCellsAction.new(amount, player_id, is_empty))
	
func change_energy(amount: int, player_id: String) -> void:
	add_action(ChangeEnergyAction.new(amount, player_id))


func sacrifice_card(card_id: String) -> void:
	add_action(SacrificeCardAction.new(card_id))


func oppose_pos(pos: Vector2i) -> Vector2i:
	return BoardManager.oppose_pos(pos)


## Get the positon of the card on the board. [param card_id] default to [member attached_card]'s id
func get_pos(card_id := "") -> Vector2i:
	if card_id.is_empty():
		card_id = attached_card.id
	return fight_manager.board_manager.get_card_pos(card_id)


## Return the 2 neighbouring spot, The array will always be of length 2 with the first item being
## left slot and second the right slot. If the slot didn't exist the item would be
## [code]null[/code], set [param include_null] to [code]false[/code] to avoid this.
func get_neighbour_slot(include_null := true) -> Array[BoardManager.Slot]:
	var pos := fight_manager.board_manager.get_card_pos(attached_card.id)
	var out: Array[BoardManager.Slot]
	var t := [
		fight_manager.board_manager.get_slot(pos + Vector2i.LEFT),
		fight_manager.board_manager.get_slot(pos + Vector2i.RIGHT)
	]
	out.assign(t.filter(func(s: BoardManager.Slot) -> bool: if s == null and include_null: return true else: return s != null))
	return out


func controller_id(pos := Vector2i.MIN) -> String:
	if pos == Vector2i.MIN:
		pos = fight_manager.board_manager.get_card_pos(attached_card.id)
	return (Global.uuid as String) if pos.y == BoardManager.Row.MINE else fight_manager.opp_id


func get_config(config_name: String, default: Variant) -> Variant:
	var config: Variant = attached_card.card_data.metadata.get(config_name)
	if typeof(config) != typeof(default):
		return default
	return config


func request_target(
	player_id: String,
	filter := func(_slot: BoardManager.Slot) -> bool: return true,
) -> BoardManager.Slot:
	var slot: BoardManager.Slot = null
	if player_id == Global.uuid:
		fight_manager.state = FightManager.State.TARGET
		while slot == null or not filter.call(slot):
			slot = await fight_manager.target_acquired
		fight_manager.state = FightManager.State.IDLE
		var p := oppose_pos(slot.pos)
		ConnectionManager.send(
			ConnectionManager.GameMessage.TARGET_ACQUIRED, {pos = {x = p.x, y = p.y}}
		)
	else:
		var packet: Dictionary = {}
		while packet == {} or packet.type != ConnectionManager.GameMessage.TARGET_ACQUIRED:
			packet = await ConnectionManager.recieved_packet
		slot = fight_manager.board_manager.get_slot(
			Vector2i(packet.pos.x as int, packet.pos.y as int)
		)
	return slot
