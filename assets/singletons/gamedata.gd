extends Node

@onready var cycle:Node2D = get_node("/root/World/Cycle")
@onready var tilemap:TileMap = get_node("/root/World/Tilemap")
@onready var player:Node2D = get_node("/root/World/Camera")

@onready var language:Control = get_node("/root/World/User Interface/Windows/Options/Panel/Main/HBoxContainer/VBoxContainer/VBoxContainer/Language")

@onready var balance:Control = get_node("/root/World/User Interface/Hud/Main/Indicators/Balance")
@onready var inventory:Control = get_node("/root/World/User Interface/Windows/Inventory")
@onready var craft:Control = get_node("/root/World/User Interface/Windows/Crafting")
@onready var mailbox:Control = get_node("/root/World/User Interface/Windows/Mailbox")

@onready var grid:Node2D = get_node("/root/World/Buildings/Grid")
@onready var grid_collision:Area2D = get_node("/root/World/Buildings/Grid/GridCollision")
@onready var farming:Node2D = get_node("/root/World/Farming")
@onready var plant:PackedScene = load("res://assets/nodes/farming/plant.tscn")

@onready var buildings:Node2D = get_node("/root/World/Buildings")
@onready var house:Node2D = get_node("/root/World/Buildings/House")
@onready var storage:Node2D = get_node("/root/World/Buildings/Storage")
@onready var animaltall:Node2D = get_node("/root/World/Buildings/Animal Stall")
@onready var silo:Node2D = get_node("/root/World/Buildings/Silo")

var object_created:int
var path = {
	game = "user://game.json",
	farm = "user://farm.json",
	world = "user://world.json",
	player = "user://player.json",
	buildings = "user://buildings.json",
	vectors = "user://vectors.json",
	crafting = "user://crafting.json",
	inventory = "user://inventory.json",
	mailbox = "user://mailbox.json",
}

func _ready():
	if GameLoader.mode:
		gameload()
		GameLoader.loading(false)
	else:
		# StartTutorial()
		pass

func gamesave() -> void:
	file_save(path.game, "settings")

	file_save(path.farm, "farm")
	file_save(path.world, "nature")
	file_save(path.player, "player")
	file_save(path.buildings, "buildings")
	file_save(path.vectors, "vectors")
	file_save(path.crafting, "crafting")
	file_save(path.inventory, "inventory")
	file_save(path.mailbox, "mailbox")

func gameload() -> void:
	remove_all_child(farming)
	terrains_remove()
	time_load()
	player_load()
	plant_load()
	
func file_save(path_file, content) -> void:
	var json_string = JSON.stringify(get_content(content), "\t")
	var file = FileAccess.open(path_file,FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	
func file_load(path_file) -> Dictionary:
	var file = FileAccess.open(path_file,FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		return parse_result
	else:
		push_error("file not found: ", path)
		return {}
		
func get_key(path_file:String, key:String, group:String = ""):
	var file = file_load(path_file)
	if group != "":
		if file.has(str(group))\
		and typeof(file[str(group)]) == TYPE_DICTIONARY:
			var container = file[str(group)]
			if container.has(str(key)):
				return container[str(key)]
			return {}
	else:
		if file.has(str(key)):
			return file[str(key)]
		return {}

func create_terrain(index:int, layer:int, path_file:String, key:String, terrain_set:int, terrain:int):
	match index:
		0:
			var string_array = get_key(path_file, key)
			var vector_array = []
			for str in string_array:
				var cleaned_str = str.replace("(", "").replace(")", "")
				var components = cleaned_str.split(",")
				var x = components[0].to_float()
				var y = components[1].to_float()
				vector_array.append(Vector2(x, y))
				
				tilemap.set_cells_terrain_connect(layer, vector_array, terrain_set, terrain)
		1:
			var string_array = get_key(path_file, key)
			var vector_array = []
			for str in string_array:
				var cleaned_str = str.replace("(", "").replace(")", "")
				var components = cleaned_str.split(",")
				var x = components[0].to_float()
				var y = components[1].to_float()
				vector_array.append(Vector2(x, y))
			
			for vector in vector_array:
					tilemap.set_cell(layer, vector, 0, Vector2i(0,3))
		2: 
			var string_array = get_key(path_file, key)
			var vector_array = []
			for str in string_array:
				var cleaned_str = str.replace("(", "").replace(")", "")
				var components = cleaned_str.split(",")
				var x = components[0].to_float()
				var y = components[1].to_float()
				vector_array.append(Vector2(x, y))
				
			for vector in vector_array:
				return vector_array

func get_content(content:String) -> Dictionary:
	match content:

		"settings": 
			return {
				"version": ProjectSettings.get_setting("application/config/version"),
				"language": language.next_lang,
			}

		"player":
			return {
				"balance": balance.money,
			}
			
		"nature":
			return {
				"time": {
					"year": cycle.year,
					"month": cycle.month,
					"week": cycle.week,
					"day": cycle.day,
					"hour": cycle.hour,
					"minute": cycle.minute,
					"cycle": cycle.get_time()
				}
			}
			
		"vectors":
			return {
				"road": grid_collision.get_used_cells(grid_collision.ground_layer),
				"farmlands": grid_collision.get_used_cells(grid_collision.farming_layer),
				"waterings": grid_collision.get_used_cells(grid_collision.watering_layer),	
				"plants": get_position_children(farming),
			}
			
		"farm":
			return get_children_data(farming)
			
		"building":
			return buildings.get_buildings()

		"inventory":
			return inventory.get_items()

		"craft":
			return craft.get_blueprints()

		"mailbox":
			return mailbox.get_letters()

		_:
			return {}

func get_position_children(parent:Node2D) -> Array:
	var children = parent.get_children()
	var coordinates = []
	for child in children:
		if child is Node2D:
			coordinates.append(tilemap.local_to_map(child.global_position))
	return coordinates

func create_nodes(parent:Node2D, node: PackedScene, positions) -> void:
	if positions != null:
		for position in positions:
			var object = node.instantiate()
			if position is Vector2:
				object_created +=1
				object.name = "Plant_" + str(object_created)
				var object_name = "Plant_" + str(object_created)
				object.global_position = tilemap.map_to_local(position)
				object.z_index = 6
				if object.has_method("check_node"):
					parent.add_child(object)
					farm_load(object, object_name, position)
				else:
					push_error("Cannot load node.")
			else:
				push_error("Variable position is not of type Vector2")

func remove_all_child(parent: Node):
	erase_cells(grid_collision.seeds_layer)
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	object_created = 0
	
func erase_cells(layer: int) -> void:
	var used_cells = tilemap.get_used_cells(layer)
	for cell in used_cells:
		tilemap.erase_cell(layer, cell)
	
func get_children_data(parent: Node) -> Dictionary:
	var data_dict = {}
	for child in parent.get_children():
		if child.has_method("get_data"):
			var child_data = child.get_data()
			data_dict[child.name] = child_data
	return data_dict

func plant_load():
	create_terrain(0, grid_collision.ground_layer, path.vectors, "road", grid_collision.ground_terrain_set, grid_collision.ground_terrain)
	create_terrain(0, grid_collision.farming_layer, path.vectors, "farmlands", grid_collision.farming_terrain_set, grid_collision.farming_terrain)
	create_terrain(0, grid_collision.watering_layer, path.vectors, "waterings", grid_collision.watering_terrain_set, grid_collision.watering_terrain)
	create_terrain(1, grid_collision.seeds_layer, path.vectors, "plants", 0, 0)
	create_nodes(farming, plant, create_terrain(2, grid_collision.seeds_layer, path.vectors, "plants", -1, -1))

func farm_load(object:Node2D, object_name:String, position):
	var plant_id = get_key(path.plants, object_name, "plantID")
	var condition = get_key(path.plants, object_name, "condition")
	var degree = get_key(path.plants, object_name, "degree")
	var fertilizer = get_key(path.plants, object_name, "fertilizer")
	var region_rect_x = get_key(path.plants, object_name, "region_rect.x")
	var region_rect_y = get_key(path.plants, object_name, "region_rect.y")
	var level = get_key(path.plants, object_name, "level_growth")

	if plant_id != null\
	and condition != null\
	and degree != null\
	and fertilizer != null\
	and region_rect_x != null\
	and region_rect_y != null\
	and level != null:
		object.set_data(plant_id, condition, degree, fertilizer, region_rect_x, region_rect_y, level, position)
	else:
		push_error("Data missing for node: " + object_name)

func terrains_remove() -> void:
	if grid_collision.get_used_cells(grid_collision.ground_layer) != []:
		tilemap.set_cells_terrain_connect(
			grid_collision.ground_layer,
			grid_collision.get_used_cells(grid_collision.ground_layer),
			grid_collision.ground_terrain_set,
			-1
		)
		
	if grid_collision.get_used_cells(grid_collision.farming_layer) != []:
		tilemap.set_cells_terrain_connect(
			grid_collision.farming_layer,
			grid_collision.get_used_cells(grid_collision.farming_layer),
			grid_collision.farming_terrain_set,
			-1
		)
		
	if grid_collision.get_used_cells(grid_collision.watering_layer) != []:
		tilemap.set_cells_terrain_connect(
			grid_collision.watering_layer,
			grid_collision.get_used_cells(grid_collision.watering_layer),
			grid_collision.watering_terrain_set,
			-1
		)

func time_load() -> void:
	cycle.year = get_key(path.world, "year", "time")
	cycle.month = get_key(path.world, "month", "time")
	cycle.week = get_key(path.world, "week", "time")
	cycle.day = get_key(path.world, "day", "time")
	cycle.hour = get_key(path.world, "hour", "time")
	cycle.minute = get_key(path.world, "minute", "time")
	cycle.timeload(get_key(path.world, "cycle", "time"))

func player_load() -> void:
	balance_load()
	inventory_load()
	craft_load()
	mailbox_load()

func balance_load() -> void:
	balance.money = get_key(path.player, "balance")
	balance.balance_update()

func inventory_load() -> void:
	inventory.items_load(get_key(path.inventory, "inventory"))

func craft_load() -> void:
	craft.blueprints_load(get_key(path.crafting, "craft"))

func mailbox_load() -> void:
	mailbox.letters_load(file_load(path.mailbox))
