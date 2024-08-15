extends Button

@onready var json = get_node("/root/World")
@onready var pause:Control = get_node("/root/World/User Interface/Windows/Pause")
@onready var time:Control = get_node("/root/World/User Interface/Hud/Time")
@onready var blackout:Control = get_node("/root/World/User Interface/Blackout")
@onready var player:CharacterBody2D = get_node("/root/World/Camera")

@onready var path:String = "res://levels/main.tscn"

func _on_pressed() -> void:
	if pause.paused:
		blackout.blackout(true)
		await get_tree().create_timer(1.25).timeout
		json.gamesave()
		get_tree().change_scene_to_file(path)
		
