extends Node2D

@onready var main:String = str(get_tree().root.get_child(1).name)
@onready var data:Node2D = get_node("/root/"+main)
@onready var pause:Control = get_node("/root/"+main+"/UI/Interactive/Pause")
@onready var hud:Control = get_node("/root/"+main+"/UI/HUD/GameHud")
@onready var inventory:Control = get_node("/root/"+main+"/UI/Interactive/Inventory")
@onready var blur:Control = get_node("/root/"+main+"/UI/Decorative/Blur")
@onready var building:Node2D = get_node("/root/"+main+"/ConstructionManager")
@onready var tilemap:TileMap = get_node("/root/"+main+"/Tilemap")
@onready var farming:Node2D = get_node("/root/"+main+"/FarmingManager")
@onready var farm:Node2D = get_node("/root/"+main+"/")

@onready var grid:Sprite2D = $Sprite2D
@onready var collision:Area2D = $GridCollision
@onready var default:CompressedTexture2D = load("res://assets/resources/ui/hud/grid/default.png")
@onready var error:CompressedTexture2D = load("res://assets/resources/ui/hud/grid/error.png")

enum modes {NOTHING, DESTROY, FARMING, PLANTING, WATERING, BUILD, TERRAIN_SET, UPGRADE}
var mode:int = modes.NOTHING
var check:bool = false

#
var inventory_item
var plantID

var building_id
var building_node
var building_shadow:CompressedTexture2D
var terrain_set:int
var upgrade
#

func _ready():
	z_index = 10
	grid.texture = default
	visible = false
	
func _input(event):
	if !blur.state and mode != modes.NOTHING:
		hud.state(true)
		if event is InputEventMouseButton\
		and event.button_index == MOUSE_BUTTON_LEFT\
		and event.is_pressed()\
		and visible:
			check = true

		if event is InputEventMouseButton\
		and event.button_index == MOUSE_BUTTON_RIGHT\
		and event.is_pressed()\
		and visible:
			_reset_grid()
			check = false

func _process(_delta):
	if !blur.state\
	and visible\
	and mode != modes.NOTHING:
		var mouse_pos:Vector2 = get_global_mouse_position()
		var tile_mouse_pos = tilemap.local_to_map(mouse_pos)
		var ground_tile_position = []
		var farming_tile_position = []
		var watering_tile_position = []
		var building_tile_position = []
		match mode:
			modes.DESTROY:
				collision.destroy_collision_check()
				if check:
					match collision.destroy_collision_check():
						0:
							tilemap.set_cells_terrain_connect(collision.road_layer,[tile_mouse_pos],collision.ground_terrain_set,-1)
						1:
							tilemap.set_cells_terrain_connect(collision.farmland_layer,[tile_mouse_pos],collision.farming_terrain_set,-1)
						2:
							tilemap.set_cells_terrain_connect(collision.watering_layer,[tile_mouse_pos],collision.watering_terrain_set,-1)
						3:
							tilemap.erase_cell(collision.seed_layer,tile_mouse_pos)
							farming.plant_destroy(tilemap.map_to_local(tile_mouse_pos))
						4:
							tilemap.erase_cell(collision.seed_layer,tile_mouse_pos)
							farming.plant_destroy(tilemap.map_to_local(tile_mouse_pos))
				check = false

			modes.FARMING:
				collision.farming_collision_check()
				if check:
					if collision.farming_collision_check():
						farming_tile_position.append(tile_mouse_pos)
						tilemap.set_cells_terrain_connect(collision.farmland_layer,farming_tile_position,collision.farming_terrain_set,collision.terrain)
				check = false

			modes.WATERING:
				collision.watering_collision_check()
				if check:
					if collision.watering_collision_check():
						watering_tile_position.append(tile_mouse_pos)
						tilemap.set_cells_terrain_connect(collision.watering_layer,watering_tile_position,collision.watering_terrain_set,collision.terrain)
				check = false

			modes.PLANTING:
				collision.planting_collision_check()
				if inventory.check_item_amount(inventory_item):
					if check:
						if inventory.get_item_amount(inventory_item) > 0:
							if collision.planting_collision_check():
								if Crops.new().crops.has(plantID):
									inventory.subject_item(inventory_item, 1)
									farming.crop(plantID, tile_mouse_pos)
								else:
									data.debug("The numerical ID (" + str(plantID) + ") of this crop is missing in the main file crops.gd", "error")
				else:
					hud.state(false)
					mode = modes.NOTHING
					visible = false
				check = false

			modes.BUILD:
				var blueprint = Blueprints.new().content[building_id]
				var data_resources = {}
				collision.building_collision_check(collision.building_layer)
				if blueprint.has("resource"):
					for resource in blueprint["resource"]:
						var required_amount = blueprint["resource"][resource]
						var available_amount = inventory.get_item_amount(BuildingMaterials.new().resources[resource])
						if available_amount >= required_amount:
								building_tile_position.append(tile_mouse_pos)
								data_resources[resource] = {}
								data_resources[resource]["amount"] = blueprint["resource"][resource]
						else:
							_reset_grid()
				if check:
					var blueprints = Blueprints.new()
					if blueprints.content.has(building_id):
						building.construct(building_id, building_node, building_shadow, tile_mouse_pos)
						if blueprints.content[building_id].has("resource"):
							inventory.subject_item(data_resources)
				check = false

			modes.TERRAIN_SET:
				collision.terrain_collision_check(collision.road_layer)
				if check:
					if collision.terrain_collision_check(collision.road_layer):
						ground_tile_position.append(tile_mouse_pos)
						tilemap.set_cells_terrain_connect(collision.road_layer,ground_tile_position,terrain_set,collision.terrain)
				check = false

			modes.UPGRADE:
			#	collision.upgrade_collision_check()
				if check:
					print("upgrade!")
				check = false
	else:
		mode = modes.NOTHING
		visible = false
		check = false

func _reset_grid() -> void:
	hud.state(false)
	mode = modes.NOTHING
	visible = false

func change_sprite(sprite:bool):
	if sprite:
		grid.texture = error
	else:
		grid.texture = default
