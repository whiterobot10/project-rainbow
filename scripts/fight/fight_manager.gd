class_name FightManager
extends Control

enum State {
	## The idle state, the fightmanager have nothing to do
	IDLE,
	## A card is selected and awaiting slot selection
	PLAYING_CARD,
	## Awaiting a cost to be pay
	PAYING_COST,
	## Hammer time!!! :DDDD
	HAMMER,
	SACRIFICE,
	RESOLVING_STACK,
	TARGET
}

@onready var hand_manager: HandManager = %HandManager
@onready var board_manager: BoardManager = %BoardManager
@onready var card_manager: CardsManager = %CardsManager

signal stack_resolved
signal just_resolved

signal target_acquired(slot: BoardManager.Slot)

var state := State.IDLE
var in_combat := false
var turn := 1
## Am I the active player
var is_active: bool:
	set(new):
		is_active = new
		%Blocker.visible = not is_active
## The current scale position. Positive is me winnig and negative is me losing.
var scale_position := 0:
	set(new):
		scale_position = new
		$VBoxContainer/HBoxContainer2/LeftUI/Scales.text = "Scales: " + str(scale_position)

var _opp_private: Array[Array] = []
var _opp_replacement: Array[Array] = []

var my_data: Player
var opp_data: Player

var sac_candidate: Array[Card] = []

var opp_id: String


class Deck:
	var main: Array[Ruleset.CardData] = []
	var side: Array[Ruleset.CardData] = []

	func _init(m: Array[Ruleset.CardData], s: Array[Ruleset.CardData]) -> void:
		main = m
		side = s
		main.shuffle()
		side.shuffle()


var deck: Deck


func _process(_delta: float) -> void:
	if opp_data == null or my_data == null:
		return
	$VBoxContainer/HBoxContainer2/LeftUI/OppHandSize.text = (
		"Opp Hand Size:" + str(opp_data.hand_size)
	)
	$VBoxContainer/HBoxContainer2/LeftUI/OppPublic.text = (
		"Opp Public Card:"
		+ ", ".join(opp_data.public_card.map(func(c: Card) -> String: return c.card_name))
	)
	$VBoxContainer/HBoxContainer2/LeftUI/Bone.text = "Bones: " + str(my_data.bones)
	$VBoxContainer/HBoxContainer2/LeftUI/Cell.text = "Energy Cells: " + str(my_data.cells)
	$VBoxContainer/HBoxContainer2/LeftUI/Energy.text = "Energy: " + str(my_data.energy)
	$VBoxContainer/HBoxContainer2/LeftUI/OppBone.text = "Opp Bones: " + str(opp_data.bones)
	$VBoxContainer/HBoxContainer2/LeftUI/OppCell.text = "Opp Energy Cells: " + str(opp_data.cells)
	$VBoxContainer/HBoxContainer2/LeftUI/OppEnergy.text = ("Opp Energy: " + str(opp_data.energy))
	_update_cursor()


func _update_cursor() -> void:
	var texture: String = "res://asset/cursor/default.png"
	match state:
		State.SACRIFICE:
			texture = "res://asset/cursor/sacrifice.png"
		State.PLAYING_CARD:
			texture = "res://asset/cursor/play_card.png"
		State.HAMMER:
			texture = "res://asset/cursor/hammer.png"
		State.TARGET:
			texture = "res://asset/cursor/target.png"
	Input.set_custom_mouse_cursor(load(texture))


class Player:
	var lives: int = 2
	var bones: int = 0
	var cells: int = 1
	var energy: int = 1
	var mox: Card.Costs.Mox
	## The player hand size
	var hand_size: int = 0
	## The cards in the player hand that is public information
	var public_card: Array[Card] = []


# --- FIGHT UTILS ---


func _start_fight(deck_dict: Dictionary) -> void:
	visible = true
	my_data = Player.new()
	opp_data = Player.new()
	var main_deck: Array[Ruleset.CardData] = []
	for card_name: String in deck_dict.main.keys():
		var card_data := Global.get_card_by_name(card_name)
		if card_data == null:
			push_warning("Can't find card %s while loading deck, skipping..." % card_name)
			continue
		for i in deck_dict.main[card_name] as int:
			main_deck.append(card_data)
	deck = Deck.new(main_deck, Global.ruleset.resolve_side_deck(deck_dict.side as Dictionary))
	await _draw_starting_hand()


func lose_game() -> void:
	%Blocker.visible = true
	%ResultPopup.visible = true
	$Blocker/CenterContainer/Label.visible = false


func _draw_starting_hand() -> void:
	for i in range(3):
		_push_action(DrawCardAction.new(DrawCardAction.Deck.MAIN, Global.uuid))
	_push_action(DrawCardAction.new(DrawCardAction.Deck.SIDE, Global.uuid))
	for i in range(3):
		_push_action(DrawCardAction.new(DrawCardAction.Deck.MAIN, opp_id))
	_push_action(DrawCardAction.new(DrawCardAction.Deck.SIDE, opp_id))
	@warning_ignore("missing_await")
	await _resolve_stack()
	await get_tree().process_frame
	hand_manager.position_card()


func get_data(player_id: String) -> Player:
	return my_data if player_id == Global.uuid else opp_data


func count_sigil(sigil: String) -> int:
	return get_cards().filter(func(c: Card) -> bool: return c.sigils.has(sigil)).size()


func has_sigil(sigil: String, row := BoardManager.Row.MINE) -> bool:
	return get_cards(row).any(func(c: Card) -> bool: return c.sigils.has(sigil))


func get_moxes(row := BoardManager.Row.MINE) -> Card.Costs.Mox:
	var mox := Card.Costs.Mox.new()
	for c: Card in get_cards(row):
		mox.add(c.mox_value())
	return mox


func get_cards(row := BoardManager.Row.MINE) -> Array[Card]:
	var t: Array[Card]
	t.assign(
		(
			board_manager
			. get_row(row)
			. map(func(s: BoardManager.Slot) -> Card: return s.card)
			. filter(func(c: Card) -> bool: return c != null)
		)
	)
	return t


func active_id() -> String:
	return (Global.uuid as String) if is_active else opp_id


# --- GODOT EVENT ---


func _ready() -> void:
	ConnectionManager.recieved_packet.connect(_on_recieved_packet)
	visible = true
	await get_tree().process_frame
	visible = false


func _on_recieved_packet(packet: Dictionary) -> void:
	if (
		packet.type != ConnectionManager.GameMessage.ACTIONS
		and packet.type != ConnectionManager.GameMessage.REPLACEMENTS
	):
		return

	var actions: Array[Action]
	actions.assign(
		(packet.actions as Array[Dictionary]).map(
			func(a: Dictionary) -> Action: return Action.from_dict(a)
		)
	)

	if packet.type == ConnectionManager.GameMessage.ACTIONS:
		if packet.private as bool:
			_opp_private.push_front(actions)
		else:
			_push_actions(actions)
			@warning_ignore("missing_await")
			_resolve_stack()
	else:
		_opp_replacement.append(actions)


func _on_slot_selected(slot: BoardManager.Slot) -> void:
	if state == State.PLAYING_CARD and slot.pos.y == BoardManager.Row.MINE:
		if slot.card != null:
			return
		var card := hand_manager.selected
		var actions: Array[Action] = []
		if card.costs.bone != 0:
			actions.push_front(ChangeBonesAction.new(-card.costs.bone as int, Global.uuid))
		if card.costs.cell != 0:
			actions.push_front(ChangeCellsAction.new(-card.costs.cell as int, Global.uuid, false))
		if card.costs.energy != 0:
			actions.push_front(ChangeEnergyAction.new(-card.costs.energy as int, Global.uuid))

		actions.push_front(PlayCardAction.new(card.id, slot.pos, Action.IDType.PLAYER, Global.uuid))
		_push_actions(actions)
		@warning_ignore("missing_await")
		_resolve_stack()
		ConnectionManager.send(
			ConnectionManager.GameMessage.ACTIONS,
			{
				actions = actions.map(func(a: Action) -> Dictionary: return a.as_dict()),
				private = false
			}
		)
		await stack_resolved
		state = State.IDLE

	if state == State.SACRIFICE and slot.pos.y == BoardManager.Row.MINE:
		if slot.card == null:
			return
		var card := slot.card
		if card in sac_candidate:
			sac_candidate.remove_at(sac_candidate.find(card))
			card.card_name = card.card_data.name
		else:
			sac_candidate.append(card)
		card.get_node("SacMarker").visible = card in sac_candidate
		var total := 0
		var actions: Array[Action] = []
		sac_candidate.sort_custom(
			func(ca: Card, cb: Card) -> bool:
				return board_manager.get_card_pos(ca.id).x > board_manager.get_card_pos(cb.id).x
		)
		for c: Card in sac_candidate:
			total += c.blood_value()
			actions.push_back(SacrificeCardAction.new(c.id))
		if total >= hand_manager.selected.costs.blood:
			for c in sac_candidate:
				c.get_node("SacMarker").visible = false
			_push_actions(actions)
			ConnectionManager.send(
				ConnectionManager.GameMessage.ACTIONS,
				{
					actions = actions.map(func(a: Action) -> Dictionary: return a.as_dict()),
					private = false
				}
			)
			await _resolve_stack()
			state = State.PLAYING_CARD

	if state == State.TARGET:
		target_acquired.emit(slot)


func _on_card_selected(card: Card) -> void:
	if state != State.IDLE:
		return
	sac_candidate.clear()
	hand_manager.selected = null
	if my_data.bones < card.costs.bone:
		return
	if my_data.cells < card.costs.cell:
		return
	if my_data.energy < card.costs.energy:
		return
	if card.costs.blood != 0:
		var total := 0
		for c: Card in get_cards():
			total += c.blood_value()
		if total < card.costs.blood:
			return
		state = State.SACRIFICE
		hand_manager.selected = card
		return
	if not card.costs.mox.is_empty():
		var mox := Card.Costs.Mox.new()
		for c: Card in get_cards():
			mox.add(c.mox_value())
		if card.costs.mox.green > mox.green:
			return
		if card.costs.mox.orange > mox.orange:
			return
		if card.costs.mox.blue > mox.blue:
			return
	hand_manager.selected = card
	state = State.PLAYING_CARD


func _on_card_unselected(_card: Card) -> void:
	if state == State.PLAYING_CARD or state == State.SACRIFICE:
		state = State.IDLE
		for c in sac_candidate:
			c.get_node("SacMarker").visible = false


func _on_end_pressed() -> void:
	if state != State.IDLE:
		return
	var a := RingBellAction.new(Global.uuid)
	_add_then_resolve(a)
	ConnectionManager.send(
		ConnectionManager.GameMessage.ACTIONS, {actions = [a.as_dict()], private = false}
	)


func _on_active_pressed(card: Card, sigil_idx: int) -> void:
	var sigil: Sigil = card._sigils.get(sigil_idx)
	if sigil == null:
		return
	if state != State.IDLE:
		return
	push_warning("hee")
	if not sigil.is_universal() and sigil.controller_id() != Global.uuid:
		return
	var a := ActivateSigilAction.new(card.id, sigil_idx, Global.uuid, Action.IDType.PLAYER)
	_push_action(a)
	ConnectionManager.send(
		ConnectionManager.GameMessage.ACTIONS, {actions = [a.as_dict()], private = false}
	)
	await _resolve_stack()


# --- STACK SHIT ---

## The top of the stack is at 0, this shouldn't be modify directly but instead through
## [method add_to_stack]
var _stack: Array[Action] = []


## Add an action to the stack. This should be use instead of changing [member _stack]
## manually.
func _push_action(action: Action) -> void:
	action.id = get_next_stack_id()
	_stack.push_back(action)


func get_next_stack_id(base: Action = null) -> String:
	if base == null and not _stack.is_empty():
		seed(_stack[-1].id.hash())
	return Global.gen_id()


func _push_actions(actions: Array[Action]) -> void:
	for a in actions:
		_push_action(a)


## This add an action to the stack then resolve the stack immedietly.
##
## Unless you know what you are doing, don't use this method and just use
## [method add_to_stack] instead and let the game handle the resolution for you
func _add_then_resolve(action: Action) -> void:
	_push_action(action)
	@warning_ignore("missing_await")
	_resolve_stack()


## resolve the first item on top of the stack
func _resolve_stack() -> void:
	state = State.RESOLVING_STACK
	while _stack.size() > 0:
		var action: Action = _stack.pop_back()
		just_resolved.emit()
		var replacement := await _get_replacement(action)
		if not replacement.is_empty():
			_stack.append_array(replacement)
			continue
		$VBoxContainer/HBoxContainer2/RightUI/RichTextLabel.text = (
			"TOP: "
			+ action.fmt()
			+ "\n"
			+ "\n".join(_stack.map(func(x: Action) -> String: return x.fmt()))
		)
		# HACK: Super janky fix that slightly delay play card on card that don't exist on the
		# current client and so the other client can resolve it first and transfer the information
		# over :)
		@warning_ignore("static_called_on_instance")
		if (
			action.action_type() == Action.Type.PLAY_CARD
			and action.card_id not in card_manager._cards.keys()
		):
			while action.card_id not in card_manager._cards.keys():
				await ConnectionManager.recieved_packet
		randomize()
		action.resolve(self)
		while _opp_private.is_empty():
			await ConnectionManager.recieved_packet
		var private_trigger: Array[Action]
		private_trigger.assign(_opp_private.pop_back() as Array)
		_push_actions(private_trigger)
		handle_static()
		#await get_tree().create_timer(0.5).timeout
	stack_resolved.emit()
	replacement_history.clear()
	$VBoxContainer/HBoxContainer2/RightUI/RichTextLabel.text = ""
	state = State.IDLE


var replacement_history: Dictionary[Sigil, Array]


func _find_replacement(cards: Array[Card], action: Action) -> Dictionary:
	for card in cards:
		for sigil: Sigil in card._sigils:
			if sigil in replacement_history and replacement_history[sigil].has(action.id):
				continue

			seed(card.id.hash() + (0 if _stack.is_empty() else _stack[-1].id.hash()))
			@warning_ignore("static_called_on_instance", "redundant_await")
			var replacement := await sigil.replace_action(action.action_type(), action)

			if not replacement.is_empty():
				return {
					replacement = replacement,
					source = sigil,
				}

	return {
		replacement = [],
		source = null,
	}


# HACK: This code is kinda stinky :(
func _get_replacement(action: Action) -> Array[Action]:
	# Public information has priority.
	var result := await _find_replacement(_public_activation_order(), action)
	var replacement: Array[Action] = []
	replacement.assign(result.replacement as Array)
	var replacement_source: Sigil = result.source

	# If no public replacement exists, determine our own private replacement.
	var private_replacement: Array[Action] = []
	if replacement.is_empty():
		result = await _find_replacement(_private_activation_order(), action)
		private_replacement.assign(result.replacement as Array)
		replacement_source = result.source

	# Tell the opponent our private replacement.
	ConnectionManager.send(
		ConnectionManager.GameMessage.REPLACEMENTS,
		{actions = private_replacement.map(func(a: Action) -> Dictionary: return a.as_dict())}
	)

	# Wait for the opponent's replacement.
	while _opp_replacement.is_empty():
		await ConnectionManager.recieved_packet

	var opp_replacement: Array[Action]
	opp_replacement.assign(_opp_replacement.pop_back() as Array)

	if replacement.is_empty():
		var primary := private_replacement if is_active else opp_replacement
		var secondary := opp_replacement if is_active else private_replacement

		if not primary.is_empty():
			replacement = primary
		elif not secondary.is_empty():
			replacement = secondary
		else:
			replacement = []

	# ID fixing
	# The _push_action function also do this ID fixing stuff but I don't like side effect
	if not replacement.is_empty():
		replacement[0].id = action.id
		for i in range(1, replacement.size()):
			replacement[i].id = get_next_stack_id(replacement[i - 1])
		# Now we add to the replacement history this sigil and actions
		if replacement_source != null:
			for a in replacement:
				if replacement_source not in replacement_history:
					replacement_history[replacement_source] = []
				replacement_history[replacement_source].append(a.id)
	return replacement


## Handle any static ability
func handle_static() -> void:
	var sigils: Array[Sigil] = []
	for card in _public_activation_order():
		sigils.append_array(card._sigils)
	for sigil in sigils:
		sigil.static_ability(true)
	for sigil in sigils:
		sigil.static_ability(false)
	for slot in board_manager.slots:
		if slot == null:
			continue
		if slot.card != null:
			slot.card.slot_attack_buf = slot.attack_buf


func _no_activation() -> void:
	ConnectionManager.send(ConnectionManager.GameMessage.ACTIONS, {actions = [], private = true})


## The [param callback]'s signature should be `func(ActionHook) -> void`
func _activate_hooks(callback: Callable) -> void:
	await _activate_hooks_on_cards(_public_activation_order(), callback)
	var private := await _activate_hooks_on_cards(_private_activation_order(), callback)
	ConnectionManager.send(
		ConnectionManager.GameMessage.ACTIONS,
		{actions = private.map(func(a: Action) -> Dictionary: return a.as_dict()), private = true}
	)


## The [param callback]'s signature should be `func(ActionHook) -> void`
func _activate_hooks_on_cards(cards: Array[Card], callback: Callable) -> Array[Action]:
	var out: Array[Action] = []
	for card in cards:
		for sigil: Sigil in card._sigils:
			if not sigil.activate_in_hand() and card.zone == Card.Zone.HAND:
				if sigil.is_active_sigil():
					sigil.get_parent().disabled = true
				continue
			if sigil.is_active_sigil():
				sigil.get_parent().disabled = sigil.is_disable()
			seed(card.id.hash() + (0 if _stack.is_empty() else _stack[-1].id.hash()))
			sigil._stack.clear()
			await callback.call(sigil)
			_push_actions(sigil._stack)
			out.append_array(sigil._stack)

			if card._special_attack != null:
				await callback.call(card._special_attack)
	return out


func _public_activation_order() -> Array[Card]:
	var out: Array[BoardManager.Slot] = board_manager.get_active_row(is_active)
	out.append_array(board_manager.get_active_row(not is_active))
	var res: Array[Card]
	res.assign(
		(
			out
			. map(func(s: BoardManager.Slot) -> Card: return s.card)
			. filter(func(c: Card) -> bool: return c != null)
		)
	)
	res.append_array(card_manager.get_cards_by_zone(Card.Zone.GRAVEYARD))
	return res


func _private_activation_order() -> Array[Card]:
	return card_manager.get_cards_by_zone(Card.Zone.HAND)
