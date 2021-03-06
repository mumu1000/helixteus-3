extends "Panel.gd"

var tab:String
var buy_sell_scene = preload("res://Scenes/Panels/BuySellPanel.tscn")
var buy_sell
onready var inventory_grid = $Contents/Control/Inventory
var item_hovered:String = ""
var item_stack:int = 0
var item_slot:int = 0

func _ready():
	set_polygon($Background.rect_size)
	buy_sell = buy_sell_scene.instance()
	buy_sell.visible = false
	add_child(buy_sell)
	_on_Items_pressed()

func refresh():
	if tab == "items":
		_on_Items_pressed()
	elif tab == "materials":
		_on_Materials_pressed()
	elif tab == "metals":
		_on_Metals_pressed()
	elif tab == "atoms":
		_on_Atoms_pressed()
	elif tab == "particles":
		_on_Particles_pressed()
	$Tabs/Materials.visible = game.show.materials
	$Tabs/Metals.visible = game.show.metals
	$Tabs/Atoms.visible = game.show.atoms
	$Tabs/Particles.visible = game.show.particles

func _on_Items_pressed():
	tab = "items"
	$Contents/Info.text = tr("INV_ITEMS_DESC")
	Helper.set_btn_color($Tabs/Items)
	inventory_grid.visible = true
	$Contents/Control/GridContainer.visible = false
	for item in inventory_grid.get_children():
		inventory_grid.remove_child(item)
	var i:int = 0
	for item in game.items:
		var slot = game.slot_scene.instance()
		if item != null:
			slot.get_node("Label").text = String(item.num)
			slot.get_node("TextureRect").texture = load("res://Graphics/" + Helper.get_dir_from_name(item.name)  + "/" + item.name + ".png")
			slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [item.name, item.num, i])
			slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
			slot.get_node("Button").connect("pressed", self, "on_slot_press", [item.name])
		inventory_grid.add_child(slot)
		i += 1

func on_slot_over (_name:String, num:int, slot:int):
	var st:String = Helper.get_item_name(_name)
	if game.other_items_info.has(_name):
		st += "\n%s" % [tr("%s_DESC" % _name.to_upper())]
	item_slot = slot
	item_hovered = _name
	item_stack = num
	if game.help.inventory_shortcuts and not game.tutorial:
		game.help_str = "inventory_shortcuts"
		st += "\n%s\n%s\n%s\n%s\n%s" % [tr("CLICK_TO_USE"), tr("SHIFT_CLICK_TO_USE_ALL"), tr("X_TO_THROW_ONE"), tr("SHIFT_X_TO_THROW_STACK"), tr("H_FOR_HOTBAR")] + "\n" + tr("HIDE_SHORTCUTS")
	game.show_tooltip(st)

func on_slot_out():
	item_hovered = ""
	game.hide_tooltip()

func on_slot_press(name:String):
	game.hide_tooltip()
	game._on_BottomInfo_close_button_pressed()
	var num:int
	if Input.is_action_pressed("shift"):
		num = game.get_item_num(name)
	else:
		num = 1
	game.item_to_use.name = name
	game.item_to_use.num = num
	var texture
	var type:String = Helper.get_type_from_name(name)
	if type == "craft_agriculture_info":
		if game.craft_agriculture_info[name].has("grow_time"):
			game.put_bottom_info(tr("PLANT_SEED_INFO"), "plant_seed", "hide_item_cursor")
			game.item_to_use.type = "seeds"
		elif game.craft_agriculture_info[name].has("speed_up_time"):
			game.put_bottom_info(tr("CLICK_TO_FERTILIZE"), "fertilize", "hide_item_cursor")
			game.item_to_use.type = "fertilizer"
	elif type == "speedups_info":
		if game.c_v == "system" and game.science_unlocked.MAE:
			game.put_bottom_info(tr("USE_SPEEDUP_MS") % 5, "use_speedup", "hide_item_cursor")
		else:
			game.put_bottom_info(tr("USE_SPEEDUP_INFO"), "use_speedup", "hide_item_cursor")
			if game.tutorial and game.tutorial.tut_num == 19:
				game.tutorial.fade(0.4, false)
		game.item_to_use.type = "speedup"
	elif type == "overclocks_info":
		if game.tutorial and game.tutorial.tut_num < 21:
			game.popup(tr("TUTORIAL_OVERCLOCK"), 2.5)
			return
		else:
			game.put_bottom_info(tr("USE_OVERCLOCK_INFO"), "use_overclock", "hide_item_cursor")
			game.item_to_use.type = "overclock"
			if game.tutorial and game.tutorial.tut_num == 21:
				game.tutorial.fade(0.4, false)
	elif type == "other_items_info":
		if name == "hx_core":
			if len(game.ship_data) > 0:
				game.put_bottom_info(tr("CLICK_SHIP_TO_GIVE_XP"), "use_hx_core", "hide_item_cursor")
				if not game.ship_panel.visible:
					game.toggle_panel(game.ship_panel)
			else:
				game.popup(tr("NO_SHIPS_2"), 1.5)
				return
	if visible:
		game.toggle_panel(game.inventory)
	if game.shop_panel.visible:
		game.toggle_panel(game.shop_panel)
	texture = load("res://Graphics/" + Helper.get_dir_from_name(name) + "/" + name + ".png")
	game.show_item_cursor(texture)

func _on_Materials_pressed():
	tab = "materials"
	$Contents/Info.text = tr("INV_MAT_DESC")
	Helper.set_btn_color($Tabs/Materials)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	var mat_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mats)
	for mat in mat_data:
		if game.show.has(mat.name) and not game.show[mat.name]:
			mat.rsrc.visible = false
			continue
		var texture = mat.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_mat", [mat.name])
		texture.connect("mouse_exited", self, "hide_mat")
		texture.connect("pressed", self, "show_buy_sell", ["Materials", mat.name])

func _on_Metals_pressed():
	tab = "metals"
	$Contents/Info.text = tr("INV_MET_DESC")
	Helper.set_btn_color($Tabs/Metals)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	var met_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mets)
	for met in met_data:
		if game.show.has(met.name) and not game.show[met.name]:
			met.rsrc.visible = false
			continue
		var texture = met.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_met", [met.name])
		texture.connect("mouse_exited", self, "hide_met")
		texture.connect("pressed", self, "show_buy_sell", ["Metals", met.name])

func _on_Atoms_pressed():
	tab = "atoms"
	$Contents/Info.text = tr("INV_ATOMS_DESC")
	Helper.set_btn_color($Tabs/Atoms)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	var atom_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.atoms)
	for atom in atom_data:
		if game.show.has(atom.name) and not game.show[atom.name]:
			atom.rsrc.visible = false

func _on_Particles_pressed():
	tab = "particles"
	$Contents/Info.text = tr("INV_PARTICLES_DESC")
	Helper.set_btn_color($Tabs/Particles)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	Helper.put_rsrc($Contents/Control/GridContainer, 48, game.particles)

func show_buy_sell(type:String, obj:String):
	if game.money == 0:
		if type == "Materials" and game.mats[obj] == 0:
			game.popup("PURCHASE_SALE_IMPOSSIBLE", 1.5)
			return
		if type == "Metals" and game.mets[obj] == 0:
			game.popup("PURCHASE_SALE_IMPOSSIBLE", 1.5)
			return
		buy_sell.is_selling = true
	else:
		if type == "Materials" and game.mats[obj] <= 0:
			buy_sell.is_selling = false
		if type == "Metals" and game.mets[obj] <= 0:
			buy_sell.is_selling = false
	buy_sell.visible = true
	buy_sell.refresh(type, obj)
	if not game.panels.has(buy_sell):
		game.panels.push_front(buy_sell)

func show_mat(mat:String):
	game.show_tooltip(get_str(mat) + "\n" + get_str(mat, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_mat():
	game.hide_tooltip()

func show_met(met:String):
	game.show_tooltip(get_str(met) + "\n" + get_str(met, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_met():
	game.hide_tooltip()

func get_str(obj:String, desc:String = ""):
	return tr(obj.to_upper() + desc)

func _input(_event):
	if item_hovered != "":
		if Input.is_action_just_released("shift X"):
			game.items[item_slot] = null
			_on_Items_pressed()
			item_hovered = ""
			game.hide_tooltip()
		elif Input.is_action_just_released("X"):
			game.remove_items(item_hovered)
			_on_Items_pressed()
			if not game.items[item_slot]:
				item_hovered = ""
				game.hide_tooltip()
		if Input.is_action_just_released("H"):
			if game.hotbar.find(item_hovered) == -1:
				game.hotbar.append(item_hovered)
			else:
				game.hotbar.erase(item_hovered)
			game.HUD.update_hotbar()


func _on_close_button_pressed():
	game.toggle_panel(self)


