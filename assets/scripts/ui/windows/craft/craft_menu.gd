extends Control

@onready var node:PackedScene = load("res://assets/nodes/ui/windows/craft/blueprint.tscn")
@onready var pause:Control = get_node("/root/World/User Interface/Windows/Pause")
@onready var inventory:Control = get_node("/root/World/User Interface/Windows/Inventory")
@onready var blur:Control = get_node("/root/World/User Interface/Blur")
@onready var anim:AnimationPlayer = $AnimationPlayer

@onready var container:GridContainer = get_node("/root/World/User Interface/Windows/Crafting/Panel/HBoxContainer/Items/GridContainer")
@onready var caption:Label = $Panel/HBoxContainer/Info/VBoxContainer/ObjectCaption
@onready var description:Label = $Panel/HBoxContainer/Info/VBoxContainer/ObjectDescription
@onready var resources:Label = $Panel/HBoxContainer/Info/VBoxContainer/ObjectResources
@onready var timeCreate:Label = $Panel/HBoxContainer/Info/VBoxContainer/ObjectCreationTime
@onready var button:Button = $Panel/HBoxContainer/Info/VBoxContainer/Craft

var items:Object = Items.new()
var store:Object = StoreBuilding.new()
var materials:Object = BuildingMaterials.new()

var index:int
var menu:bool = false
var access:Array = [1,2,3,4,5,6,7,8,9,10]

func _ready():
	menu = false
	blur.blur(false)
	anim.play("close")
	check_blueprints(access)

func _process(delta):
	if !pause.paused\
	and !inventory.menu:
		if Input.is_action_just_pressed("pause") and menu:
			close()

func window() -> void:
	if menu:
		close()
	else:
		open()

func open() -> void:
	menu = true
	pause.other_menu = true
	blur.blur(true)
	anim.play("open")
	start_info()
	check_blueprints(access)
	
func close() -> void:
	menu = false
	pause.other_menu = false
	blur.blur(false)
	anim.play("close")
	check_blueprints(access)

func start_info() -> void:
	caption.text = "* Информация *"
	description.text = "Начните строительство, выбрав доступные чертежи слева."
	timeCreate.text = ""
	button.visible = false

func check_blueprints(array:Array) -> void:
	if menu:
		for i in array:
			create_item(i)
	else:
		delete_all_blueprints(container)

func create_item(i) -> void:
	var item = node.instantiate()
	if item.test(i):
		container.add_child(item)
		item.set_data(i)
	else:
		push_error("Cannot load node. Invalid index: " + str(i))

func delete_all_blueprints(parent) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func get_data(index:int):
	if store.content.has(index):
		self.index = index
		if store.content[index].has("caption"):
			if typeof(store.content[index]["caption"]) == TYPE_STRING and caption.text is String:
				caption.text = str(store.content[index]["caption"])
			else:
				caption.text = "Untitled blueprint"
				push_error("The 'caption' key has a non-string type. Variant.type: " + str(typeof(store.content[index]["caption"])))
		else:
			push_error("The object does not have the 'caption' key.")
			description.visible = false
			
		if store.content[index].has("description"):
			if typeof(store.content[index]["description"]) == TYPE_STRING and description.text is String:
				description.text = store.content[index]["description"] + "\n"
				description.visible = true
			else:
				push_error("The 'description' key has a non-string type. Variant.type: " + str(typeof(store.content[index]["description"])))
				description.visible = false
		else:
			push_error("The object does not have the 'description' key.")
			description.visible = false
		
		if store.content[index].has("resource"):
			resources.visible = true
			resources.text = "Необходимые ресурсы:"
			
			if store.content[index].get("resource") != {}:
				for i in store.content[index]["resource"]:
					check_material(index, i)
			else:
				push_warning("The drawing does not have the necessary resources for construction.")
				resources.visible = false
		else:
			push_error("The array of 'resources' does not exist in index: " + str(index))
			resources.visible = false
		
		if store.content[index].has("time"):
			if typeof(store.content[index]["time"]) == TYPE_INT and description.text is String:
				if store.content[index]["time"] > 0:
					timeCreate.text = "Время создания: " + str(store.content[index]["time"]) + " сек."
					timeCreate.visible = true
				else:
					timeCreate.visible = false
			else:
				push_error("The 'time' key has a non-integer type. Variant.type: " + str(typeof(store.content[index]["time"])))
				timeCreate.visible = false
		else:
			push_error("The object does not have the 'time' key.")
			timeCreate.visible = false
		
		button.visible = true
	else:
		button.visible = false

func check_material(index, key) -> void:
	if (resource(key) && check_items(key)) != null:
			if typeof(store.content[index]["resource"][key]) != TYPE_STRING:
				resources.text = resources.text + "\n• " + str(resource(key)) + " (" + str(check_items(key)) + "/" + str(round(store.content[index]["resource"][key])) + ")"
				check_button(index, key)
			else:
				push_error("The key '" + str(key) + "' does not store an integer or float: " + str(typeof(store.content[index]["resource"][key])))
	else:
		push_warning("The '" + str(key)+ "' material cannot be returned as a string. This material will not be taken into account.")

func check_button(index, key):
	if check_items(key) >= store.content[index]["resource"][key]:
		button.disabled = false
	else:
		button.disabled = true

func resource(key) -> Variant:
	if key in materials.resources:
		if materials.resources[key].has("caption"):
			return materials.resources[key]["caption"]
	return null

func check_items(key) -> Variant:
	if materials.resources[key].has("id"):
		if inventory.inventory_items.has(materials.resources[key]["id"]):
			return inventory.inventory_items[materials.resources[key]["id"]]["amount"]
		return 0
	return null

func reset_data() -> void:
	caption.text = ""
	description.text = ""
	resources.visible = false
	timeCreate.visible = false
	button.visible = false

func _on_craft_pressed():
	if button.visible:
		if !button.disabled:
			print(
				str(store.content[index]["node"])
			)

func check_window() -> void:
	visible = menu

func _on_button_pressed() -> void:
	window()
