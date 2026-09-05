@abstract class_name Action
extends Object

## Base class for an action on the stack. These can be resolve using [method resolve]
##
## When adding a new action, you should also follows this checklist:[br]
## - Add a new type to [enum Type]. [br]
## - implement [method action_type] that return your new enum value[br]
## - [method as_dict] and [method from_dict] that serialize to and from a Dictionary.[br]
## - implement [method resolve] that perform the resolution of this action as well as activating
## sigil[br]
## - A sigil event hooks [br]
## - For debug purposes you may also implement [method fmt] to format your action into a string
## A default implementation is provided for you if you don't want to implement anything.[br]
## [br]
## If you want an example look at [PlayCardAction] file.[br]
## - The enum type is [enum Type.PLAY_CARD][br]
## - The sigil event hook is [method Sigil.on_card_played][br]
## - It implement [method PlayCardAction.as_dict] and [method PlayCardAction.from_dict][br]
## - It implement [method PlayCardAction.resolve] that perform the actual playing of the card using
## helper and utility provided by [FightManager] as well as trigger sigil event hook.

enum Type {
	## Action representing nothing. This is usually use by replacement effect to fizzle an action
	NULL,
	## Action representing adding a card into the hand.
	ADD_CARD,
	## Action representing drawing a card from a deck.
	DRAW_CARD,
	## Action representing removing a card from a hand.
	DISCARD_CARD,
	## Action representing playing a card.
	PLAY_CARD,
	## Action representing creating a new token, this token will just float around in limbo.
	## You need another action to do something with this token.
	CREATE_TOKEN,
	## Action representing moving a card from one slot on the board to another.
	MOVE_CARD,
	## Action represrnting a card transforming into another.
	TRANSFORM_CARD,
	## Action representing a change in the card's BASE stats. Do not use for temporary buffs, such as Leader.
	CHANGE_STATS,
	## Action representing activating the sigil on a card. This does not mean a sigil activating,
	## this is for active sigil activation by someone or something
	ACTIVATE_SIGILS,
	## Action representing ringing the bell. This will put [CombatAction] and [EndTurnAction] onto
	## the stack
	RING_BELL,
	## Action representing starting the turn.
	START_TURN,
	## Action representing ending the turn.
	END_TURN,
	## Action representing the start of combat.
	COMBAT,
	## Action indicating the end of the combat. This don't do much but chaneg the state of the
	## fight manager back
	END_COMBAT,
	## Action representing the start of a card attack. This will simply resolve into [PreCardStrikg]
	## that actually take care of the damage and whatnot. Implementing [method Sigil.on_attack] will
	## override the default of adding a center strike for this action
	CARD_ATTACK,
	## Action representing the step just before the card strike. This provide time for sigil to
	## intervene before the card strike
	PRE_CARD_STRIKE,
	## Action representing the card striking. This is the actual damage dealing action.
	CARD_STRIKE,
	## Action representing damaging a card.
	DAMAGE_CARD,
	## Action representing the tipping of the scale.
	TIP_SCALE,
	## Action representing killing a card.
	KILL_CARD,
	## Action representing a change in bone tokens, be it losing, spending or gaining bone tokens.
	CHANGE_BONES,
	## Action representing a change in energy cells, be it losing, spending or gaining energy cells.
	CHANGE_CELLS,
	## Action represrnting a chaneg in energy, be it losing, spending or gaining energy.
	CHANGE_ENERGY,
	## Action representing the refresh in energy. Basically just set the energy back to the cells
	## amount, this does not use [ChangeEnergyAction]
	REFRESH_ENERGY,
	## Action representing sacrificing a card, this will just resolve into KILL_CARD
	SACRIFICE_CARD
}

enum IDType { CARD, PLAYER }

## A unique id for this stack action.
##
## If a previous stack action is on the stack this is use to seed the randomizer
var id := Global.gen_id()

@abstract func resolve(fight_manager: FightManager) -> void


static func action_type() -> Type:
	push_error("Action type did not implement the `action_type` static func")
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	return -1


@abstract func as_dict() -> Dictionary


func duplicate() -> Action:
	return Action.from_dict(as_dict())


static var _action_registry: Dictionary = {}


static func from_dict(dict: Dictionary) -> Action:
	if _action_registry.is_empty():
		var path := "res://scripts/fight/classes/actions"
		var dir := DirAccess.open(path)
		for file in dir.get_files():
			if not file.ends_with(".gd"):
				continue
			@warning_ignore("confusable_local_declaration")
			var script := load("%s/%s" % [path, file])
			_action_registry[script.action_type()] = script

	if "type" not in dict:
		dict.type = -1
	dict.type = dict.type as int
	if dict.type == -1:
		push_error("This action did not implement dictfication")
		return null

	var script: Script = _action_registry.get(dict.type)
	return script.from_dict(dict)


## Return the action as a nicely formatted string for debug purposes
func fmt() -> String:
	return Action.Type.keys()[action_type()]
