extends "Panel.gd"

var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
onready var amount_node = $Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount
onready var buy_btn = $Contents/HBoxContainer/ItemInfo/HBoxContainer/Buy
onready var grid = $Contents/HBoxContainer/Items/Items
onready var desc_txt = $Contents/HBoxContainer/ItemInfo/VBoxContainer/Description
var num:int = 1

var item_type:String = ""
var item_dir:String = ""
var item_costs:Dictionary
var item_desc:String = ""
var item_total_costs:Dictionary
var item_name = ""

func _ready():
	set_polygon($Background.rect_size)

func change_tab(btn_str:String):
	for item in $Contents/HBoxContainer/Items/Items.get_children():
		$Contents/HBoxContainer/Items/Items.remove_child(item)
	item_name = ""
	_on_BuyAmount_value_changed(1)
	remove_costs()
	$Contents/HBoxContainer/ItemInfo.visible = false
	$Contents.visible = true
	$Contents/Info.text = tr("%s_DESC" % btn_str.to_upper())
	Helper.set_btn_color(get_node("Tabs/%s" % btn_str))
	
func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if not child is Label and not child is RichTextLabel:
			vbox.remove_child(child)

func set_item_info(name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	$Contents/HBoxContainer/ItemInfo.visible = true
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = Helper.get_item_name(name)
	desc_txt.text = desc + "\n"
	item_costs = costs
	item_total_costs = costs.duplicate(true)
	item_name = name
	item_type = _type
	item_desc = desc
	item_dir = _dir
	for cost in costs:
		item_total_costs[cost] = costs[cost] * num
	Helper.put_rsrc(vbox, 36, item_total_costs, false, true)
	yield(get_tree().create_timer(0), "timeout")
	desc_txt.rect_min_size.y = desc_txt.get_content_height()
	desc_txt.rect_size.y = desc_txt.get_content_height()
#
#func _on_Buy_pressed():
#	get_item(item_name, item_total_costs, item_type, item_dir)

#func get_item(_name, costs, _type, _dir):
#	if _name == "":
#		return
#	item_name = _name
#	item_total_costs = costs.duplicate(true)
#	if game.check_enough(item_total_costs):
#		game.deduct_resources(item_total_costs)
#		var items_left = game.add_items(item_name, amount_node.value)
#		if items_left > 0:
#			var refund = item_costs.duplicate(true)
#			for rsrc in item_costs:
#				refund[rsrc] = item_costs[rsrc] * items_left
#			game.add_resources(refund)
#			game.popup(tr("NOT_ENOUGH_INV_SPACE_BUY"), 2.0)
#		else:
#			game.popup(tr("PURCHASE_SUCCESS"), 1.5)
#		if game.HUD:
#			game.HUD.update_hotbar()
#	else:
#		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func add_items(not_enough_inv:String, success:String):
	var items_left = game.add_items(item_name, amount_node.value)
	if items_left > 0:
		var refund = item_costs.duplicate(true)
		for rsrc in item_costs:
			refund[rsrc] = item_costs[rsrc] * items_left
		game.add_resources(refund)
		game.popup(not_enough_inv, 2.0)
	else:
		game.popup(success, 1.5)
		set_item_info(item_name, item_desc, item_costs, item_type, item_dir)
	if game.HUD:
		game.HUD.update_hotbar()

func _on_BuyAmount_value_changed(value):
	num = value
	remove_costs()
	for cost in item_costs:
		item_total_costs[cost] = item_costs[cost] * num
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	Helper.put_rsrc(vbox, 36, item_total_costs, false, true)

func refresh():
	pass

func _on_close_button_pressed():
	game.toggle_panel(self)
