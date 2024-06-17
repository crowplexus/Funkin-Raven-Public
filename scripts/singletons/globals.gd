extends Node

const MENU_MUSIC: AudioStream = preload("res://assets/audio/bgm/freakyMenu.ogg")
const MENU_MUSIC_BPM: float = 102.0

const MENU_SCROLL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/scrollMenu.ogg")
const MENU_CONFIRM_SFX: AudioStream = preload("res://assets/audio/sfx/menu/confirmMenu.ogg")
const MENU_CANCEL_SFX: AudioStream = preload("res://assets/audio/sfx/menu/cancelMenu.ogg")
const OPTIONS_WINDOW: PackedScene = preload("res://scenes/ui/options_window.tscn")


func change_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)


func get_options_window() -> Control:
	var ow: Control = OPTIONS_WINDOW.instantiate()
	ow.process_mode = Node.PROCESS_MODE_ALWAYS
	ow.z_index = 100
	return ow