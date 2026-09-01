class_name RulesetButton
extends Button

signal horvered(name: String, description: String)
signal selected(button: _ruleset_selector.RulesetIcon)

#gdlint: ignore=load-constant-name
const _ruleset_selector := preload("res://packed/ruleset_selector/ruleset_selector.gd")

@export var ruleset_name: String
@export var url: String
@export var description: String
var ruleset: _ruleset_selector.RulesetIcon


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_on_horvered)
	pressed.connect(_on_selected)
	if ruleset != null:
		ruleset_name = ruleset.name
		description = ruleset.description
		icon = load(ruleset.icon)
		url = ruleset.url
		$Installed.visible = ruleset.installed


func _on_horvered() -> void:
	horvered.emit(ruleset_name, description)


func _on_selected() -> void:
	selected.emit(ruleset)
