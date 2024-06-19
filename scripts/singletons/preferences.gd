extends Node

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
## Centers your notes and hides the enemy's.
@export var centered_playfield: bool = false
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
		if new_mode == "VSync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			if new_mode == "Unlimited":
				Engine.max_fps = 0
		framerate_mode = new_mode
## Defines how hold notes should be layered.
@export_enum("Above Notes:0", "Behind Notes:1")
var hold_layer: int = 1
## Enables a firework effect when hitting judgements that allow it.
@export var note_splashes: bool = true
## Enables certain flashing effects in menus and gameplay[br]
## please disable this if you are sensitive to those.
@export var flashing: bool = true
## Enables a timer at the top of the screen, shows song elapsed time and total time.
@export var show_timer: bool = true
## How should the countdown's speed behave when ticking?
@export_enum("BPM based:0", "User defined:1")
var countdown_mode: int = 0
## How fast the countdown ticks down, measured in steps[br]
## The higher the number, the slower it gets.
@export var countdown_speed: int = 5:
	set(new_speed):
		countdown_speed = clampi(new_speed, 1, 10)
## Language used in the menus and user interface.
@export var language: String = "en_AU":
	set(new_locale):
		language = new_locale
		TranslationServer.set_locale(new_locale)
#endregion
#region Functions

func _ready() -> void:
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

#endregion
