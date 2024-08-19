extends Control

@onready var pause:Control = get_node("/root/World/User Interface/Windows/Pause")
@onready var inventory:Control = get_node("/root/World/User Interface/Windows/Inventory")
@onready var balance:Control = get_node("/root/World/User Interface/Hud/Main/Indicators/Balance")
@onready var blur:Control = get_node("/root/World/User Interface/Blur")
@onready var animation:AnimationPlayer = $AnimationPlayer

@onready var letters_container:VBoxContainer = $Panel/HBoxContainer/LettersScroll/VBoxContainer
@onready var content_container:VBoxContainer = $Panel/HBoxContainer/ContentScroll/VBoxContainer
@onready var items_container:GridContainer = $Panel/HBoxContainer/ContentScroll/VBoxContainer/Items/VBoxContainer/HBoxContainer/Items/GridContainer
@onready var items_block:MarginContainer = $Panel/HBoxContainer/ContentScroll/VBoxContainer/Items
@onready var letter_node:PackedScene = load("res://assets/nodes/ui/windows/mail/letter.tscn")
@onready var item_node:PackedScene = load("res://assets/nodes/ui/inventory/slot.tscn")

@onready var header_label:Label = $Panel/HBoxContainer/ContentScroll/VBoxContainer/LetterHeader/Title
@onready var description_label:Label = $Panel/HBoxContainer/ContentScroll/VBoxContainer/MainContent/Text
@onready var author_label:Label = $Panel/HBoxContainer/ContentScroll/VBoxContainer/Author/Author
@onready var fixedItems_label:Label = $Panel/HBoxContainer/ContentScroll/VBoxContainer/Items/VBoxContainer/LabelContainer/Label
@onready var getItems_button:Button = $Panel/HBoxContainer/ContentScroll/VBoxContainer/Items/VBoxContainer/ButtonContainer/GetItems

var item:Object = Items.new()
var menu:bool = false
 
var letters:Dictionary = {}
var index

func _process(_delta):
	if Input.is_action_just_pressed("pause")\
	and menu:
		close()

func _ready():
	check_window()
	reset_data()
	delete_letters(letters_container)

func letter(header:String = "", description:String = "", author:String = "", money:int = 0, items:Dictionary = {}) -> void:
	var key = letters.size() + 1
	if header != ""\
	or description != "": 
		letters[key] = {}
		letters[key]["header"] = header
		letters[key]["description"] = description
		letters[key]["author"] = author
		letters[key]["money"] = money
		letters[key]["items"] = {}
		if items != {}:
			check_all_keys(key, items)

func check_all_keys(id:int, dictionary:Dictionary) -> void:
	for key in dictionary.keys():
		if !dictionary[key].has("amount"):
			if !letters[id]["items"].has(key):
				letters[id]["items"][key] = {}
			letters[id]["items"][key]["amount"] = 1
		else:
			letters[id]["items"][key] = dictionary[key]

func get_data(letterID:int) -> void:
	self.index = check_letterID(letterID)
	if letters.has(index):
		letter_delete_items(items_container)

		if letters[index].has("header"):
			if typeof(letters[index]["header"]) == TYPE_STRING:
				header_label.text = letters[index]["header"]
				header_label.visible = true
			else:
				push_error("The 'header' is not a string. Variant.type: " + str(typeof(letters[index]["header"])))
		else:
			header_label.visible = false

		if letters[index].has("description_label"):
			if typeof(letters[index]["description_label"]) == TYPE_STRING:
				description_label.text = letters[index]["description_label"]
				description_label.visible = true
			else:
				push_error("The 'description_label' is not a string. Variant.type: " + str(typeof(letters[index]["description_label"])))
		else:
			description_label.visible = false

		if letters[index].has("author"):
			if typeof(letters[index]["author"]) == TYPE_STRING:
				author_label.text = "— " + letters[index]["author"]
				author_label.visible = true
			else:
				push_error("The 'author' is not a string. Variant.type: " + str(typeof(letters[index]["author"])))
		else:
			author_label.visible = false

		if (letters[index].has("items") or letters[index].has("money"))\
		and (letters[index]["items"] != {} or letters[index]["money"] != 0):
			items_block.visible = true

			if !letters[index]["items"].has("collected"):
				getItems_button.visible = true
			else:
				getItems_button.visible = false

			if letters[index]["items"] != {}:
				for i in letters[index]["items"]:
					if typeof(letters[index]["items"][i]) == TYPE_DICTIONARY and letters[index]["items"][i].has("amount"):
						if letters[index]["items"][i]["amount"] > 0:
							letter_create_items(
								int(i), 
								int(letters[index]["items"][i]["amount"]), 
								items_container, 
								item_node
							)
						else:
							letters[index]["items"][i].erase(index)
							push_warning("Error")

			if letters[index]["money"] > 0:
				var nested_str = tr("Вложение")
				var money_str = tr("монет")
				fixedItems_label.text = nested_str + ": " + str(balance.format(letters[index]["money"])) + " " + money_str
				fixedItems_label.visible = true
			else:
				var attached_str = tr("Прикрепленные предметы")
				fixedItems_label.text = attached_str + ":"
				fixedItems_label.visible = true

		else:
			items_block.visible = false

	else:
		push_error("Invalid index: " + str(index))

func check_letterID(letterID):
	for i in letters:
		if typeof(i) == TYPE_INT:
			return int(letterID)

		if typeof(i) == TYPE_STRING:
			return str(letterID)
		else:
			return

func get_all_items(letter_id, dictionary:Dictionary) -> void:
	if dictionary[letter_id].has("items"):
		if dictionary[letter_id]["items"] != {}:
			if check_letter_item(1, letter_id, dictionary):
				check_letter_item(2, letter_id, dictionary)

	if dictionary[letter_id].has("money"):
		balance.add_money(dictionary[letter_id]["money"])

	dictionary[letter_id]["items"]["collected"] = true
	getItems_button.visible = false
		
func check_letter_item(check:int, letterID, dictionary:Dictionary):
	match check:
		1:
			if dictionary[letterID].has("items"):
				for key in dictionary[letterID]["items"]:
					if item.content.has(int(key)):
						return true
					else: return false
				
		2:
			for key in dictionary[letterID]["items"].keys():
				if item.content.has(int(key)):
					inventory.add_item(int(key), int(dictionary[letterID]["items"][key]["amount"]))
				else:
					push_error("")

func create_letters(dictionary:Dictionary, node:PackedScene, parent:VBoxContainer) -> void:
	for i in dictionary:
		var object = node.instantiate()
		parent.add_child(object)
		object.set_data(int(i), dictionary[i]["header"])

func delete_letters(parent:VBoxContainer) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
			
func letter_create_items(id:int, amount:int, parent:GridContainer, node:PackedScene) -> void:
	if item.content.has(id):
		var object = node.instantiate()
		parent.add_child(object)
		object.set_data(id, amount)
	else:
		push_error("Invalid item ID: " + str(id))
		
func letter_delete_items(parent:GridContainer) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func letters_load(data:Dictionary):
	letters = data

func get_letters() -> Dictionary:
	return letters

func reset_data() -> void:
	header_label.text = ""
	description_label.text = ""
	author_label.text = ""
	items_block.visible = false

func open() -> void:
	menu = true
	pause.other_menu = true
	blur.blur(true)
	animation.play("open")
	create_letters(letters, letter_node, letters_container)
	
func close() -> void:
	menu = false
	pause.other_menu = false
	self.index = 0
	blur.blur(false)
	animation.play("close")
	delete_letters(letters_container)

func check_window() -> void:
	visible = menu

func _on_get_items_pressed():
	if getItems_button.visible:
		get_all_items(index, letters)

func _on_close_pressed() -> void:
	if blur.bluring:
		close()
