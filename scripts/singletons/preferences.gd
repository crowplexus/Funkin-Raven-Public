extends Node

signal prefs_saved(pref: String)
signal prefs_loaded()

#region Internal

const _SAVE_FILE: = "user://raven_prefs.cfg"
var _file: ConfigFile = ConfigFile.new()

#endregion

#region Gameplay Options

## Self-explanatory.
@export var keybinds: Dictionary = {
	"note0": [	"A",	"Left"	],
	"note1": [	"S",	"Down"	],
	"note2": [	"W",	"Up"	],
	"note3": [	"D",	"Right"	],
}
## Defines which direction the notes will scroll to.
@export_enum("Up:0", "Down:1")
var scroll_direction: int = 0
## Changes how early or late the Conductor is offset to,[br]
## this will also make it so notes spawn earlier/later than usual,
## Recommended if you use bluetooth headphones.
@export var beat_offset: float = 0.0:
	set(new):
		beat_offset = clampf(snappedf(new, 0.001), -500, 500)
## Centers your notes and hides the enemy's.
@export var centered_playfield: bool = false
## Allows you to press keys while there's no notes to hit.
@export var ghost_tapping: bool = true
## Enables a new 5th judgement greater than "Sick!"
@export var use_epics: bool = true
## Defines how scroll speed behaves in-game.
@export_enum("Chart based:0", "Multiplicative:1", "Constant:2")
var scroll_speed_behaviour: int = 0
## Defines your set scroll speed, the Scroll Speed Behaviour[br]
## option will dictate how it impacts gameplay.
@export var scroll_speed: float = 1.0:
	set(new_speed):
		scroll_speed = clampf(snappedf(new_speed, 0.001), 0.5, 10.0)
## Which playfield belongs to the player?[br]
## NOTE: None will make the game enter Botplay Mode.
@export_enum("Right:0", "Left:1", "None:-1") #, "Both:3")
var playfield_side: int = 0:
	set(new_side):
		match new_side:
			2: playfield_side = -1 # temporary
			_: playfield_side = new_side

#endregion
#region Visual Options

## Define the size of the notes on-screen.
@export var receptor_size: float = 1.0:
	set(new_size):
		receptor_size = clampf(snappedf(new_size, 0.001), 0.5, 1.0)

## Define here your frames per second limit.
@export var framerate_cap: int = 60:
	set(new_framerate):
		framerate_cap = clampi(new_framerate, 30, 240)
		if framerate_mode == "Capped":
			Engine.max_fps = framerate_cap
## Define how the engine should treat framerate.
@export_enum("Capped", "Unlimited", "VSync")
var framerate_mode: String = "Capped":
	set(new_mode):
		match new_mode:
			"Capped":
				Engine.max_fps = framerate_cap
			"VSync":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
			_:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				if new_mode == "Unlimited":
					Engine.max_fps = 0
		framerate_mode = new_mode
## Defines how hold notes should be layered.
@export_enum("Above Notes:0", "Behind Notes:1")
var hold_layer: int = 1
## Enables a firework effect when hitting judgements that allow it.
@export_enum("Disabled:0", "On Player:1", "All Notefields:2")
var note_splashes: int = 2
## Enables certain flashing effects in menus and gameplay[br]
## Please disable this if you are sensitive to those.
@export var flashing: bool = true
## Enables a timer at the top of the screen, shows song elapsed time and total time.
@export var show_timer: bool = true
## Makes combo coloured after the judgements you hit.
@export_enum("None:0", "Only Judgments:1", "Only Combo:2", "Judges and Combo:3")
var coloured_combo: int = 2
## Dictates how [code]coloured_combo[/code] should colour the judgments and/or combo
@export_enum("Judgment:0", "Clear Flag:1")
var combo_colour_mode: int = 1
## Define your note colours.
@export var note_colours: Array = [
	[ # columns
		Color("#C24B99"), Color("#00FFFF"),
		Color("#12FA05"), Color("#F9393F")
	],
	[ # quants
		Color.RED, Color.BLUE, Color.PURPLE,
		Color.ORANGE, Color.MAROON, Color.LIME,
		Color.SPRING_GREEN, Color.DARK_GRAY,
		Color.INDIAN_RED, Color.NAVY_BLUE, Color.SLATE_GRAY
	]
]
## Define what note colours to show during gameplay.
@export_enum("Column:0", "Quantized:1")
var note_colouring_mode: int = 0
## Language used in the menus and user interface.
@export var language: String = "en_AU":
	set(new_locale):
		language = new_locale
		TranslationServer.set_locale(new_locale)
## Define how the status bar should display information.
@export_enum("Full:0", "No Score:1", "Only Score:2")
var status_display_mode: int = 0
## Choose a HUD Style.
@export_enum("Song-specific:0", "Raven:1", "Kade:2", "Psych:3", "Classic:4")
var hud_style: int = 0

#endregion

#region Other

var master_volume: float = 1.0:
	set(new_vol):
		master_volume = clampf(new_vol, 0.0, 1.0)
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

var bgm_volume: float = 1.0:
	set(new_vol):
		bgm_volume = clampf(new_vol, 0.0, 1.0)
		AudioServer.set_bus_volume_db(1, linear_to_db(bgm_volume))

var sfx_volume: float = 1.0:
	set(new_vol):
		sfx_volume = clampf(new_vol, 0.0, 1.0)
		AudioServer.set_bus_volume_db(2, linear_to_db(sfx_volume))

#endregion

#region Functions

func _ready() -> void:
	load_prefs()
	await RenderingServer.frame_post_draw # bro.
	init_keybinds()


func init_keybinds() -> void:
	for action_name: String in keybinds:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)

		for i: int in keybinds[action_name].size():
			var _new_event: = InputEventKey.new()
			var key: String = keybinds[action_name][i]
			_new_event.keycode = OS.find_keycode_from_string(key.to_lower())
			InputMap.action_add_event(action_name, _new_event)


func save_prefs() -> void:
	var e: Error = _file.load(_SAVE_FILE)
	if e == OK:
		var _props: Array[Dictionary] = get_vars()
		for prop: Variant in _props:
			#print_debug(prop.name)
			if prop.name.begins_with("_"):
				continue
			_file.set_value("Preferences", prop.name, get(prop.name))
		_file.save(_SAVE_FILE)
		prefs_saved.emit("ALL")
		#_file.unreference()


func load_prefs() -> void:
	var e: Error = _file.load(_SAVE_FILE)
	if e != OK:
		save_prefs()
		await prefs_saved
	var _props: Array[Dictionary] = get_vars()
	for prop: Variant in _props:
		if prop.name.begins_with("_"):
			continue
		if not _file.has_section_key("Preferences", prop.name):
			_file.set_value("Preferences", prop.name, get(prop.name))
		else:
			set(prop.name, _file.get_value("Preferences", prop.name, get(prop.name)))
	prefs_loaded.emit()
	#_file.unreference()


func save_pref(pref: String, value: Variant) -> void:
	var e: Error = _file.load(_SAVE_FILE)
	if e == OK:
		_file.set_value("Preferences", pref, value)
		_file.save(_SAVE_FILE)
		prefs_saved.emit(pref)
		#_file.unreference()

func get_vars() -> Array[Dictionary]:
	var _props: Array[Dictionary] = get_property_list()
	for _i: int in 19: _props.remove_at(0)
	return _props

#endregion
