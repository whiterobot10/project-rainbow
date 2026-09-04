@abstract class_name ActionHook
extends TextureRect

## This class is an interface that provide every action hook, new class that want to use the hook
## system should inherit from this

@warning_ignore_start("unused_parameter")  # keep the signature clean while avoiding warning


## Called after [AddCardAction] resolved. This mean that the card have already been added.
## [param card] can be [code]null[/code] if the card is not public or known to the current player.
func on_card_added(card: Card, player_id: String) -> void:
	return


## Called after [PlayCardAction] resolved. This mean that the card is already on board.
func on_card_played(
	card: Card, pos: Vector2i, placer_type: Action.IDType, placer_id: String
) -> void:
	return


func on_card_moved(card: Card, from: BoardManager.Slot, to: BoardManager.Slot) -> void:
	return


func on_card_transformed(card: Card, card_data: Ruleset.CardData) -> void:
	return


func on_card_stats_changed(card: Card, attack: int, health: int) -> void:
	return


func on_sigil_activate(
	card: Card, sigil: Sigil, source_id: String, source_type: Action.IDType
) -> void:
	return


func on_bell_rung(player_id: String) -> void:
	return


## Called after [EndTurnAction] resolved.
func on_turn_end(player_id: String) -> void:
	return


## Called after [StartTurnAction] resolved.
func on_turn_start(player_id: String) -> void:
	return


## Called when [CombatAction] resolved bef fore all the strike and attack are put onto the stack. For
## those that change how the card attack use [method on_attack].
func on_combat_start() -> void:
	return


func on_combat_end() -> void:
	return


func pre_card_strike(striker: Card, victim_slot: BoardManager.Slot, to_face: bool) -> void:
	return


func on_card_strike(striker: Card, pos: Vector2i, to_face: bool) -> void:
	pass


func on_card_damaged(
	victim: Card, amount: int, attacker_type: Action.IDType, attacker_id: String
) -> void:
	return


## Called just before [KillCardAction] resolved. This mean that the card haven't actually die or
## been move to the graveyard
func on_card_perished(card: Card) -> void:
	return


## Called after [TipScaleAction] resolved. This means that the scale is already tipped.
func on_scale_tipped(amount: int) -> void:
	return


## Called after [ChangeBonesAction] resolved. This means that the bones already changed. [death_card]
## is the card that die to produce this bone, can be [code]null[/code] if bone changed otherwise
func on_bone_changed(amount: int, player_id: String, death_card: Card) -> void:
	return


func on_cell_changed(amount: int, player_id: String) -> void:
	return


func on_energy_changed(amount: int, player_id: String) -> void:
	return


func on_energy_refresh(player_id: String) -> void:
	return


## Called after [SacrificeCardAction] resolved. This means the ard is still alive and on the board.
func on_card_sacrificed(card: Card) -> void:
	return
