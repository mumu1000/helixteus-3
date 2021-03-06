extends Control

onready var game = get_node("/root/Game")
onready var current = $Current
onready var ship0 = $Ship0
onready var ship1 = $Ship1
const DEF_EXPO = 0.7
var victory_panel_scene = preload("res://Scenes/Panels/VictoryPanel.tscn")
var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
var target_scene = preload("res://Scenes/TargetButton.tscn")
var HP_icon = preload("res://Graphics/Icons/HP.png")
var atk_icon = preload("res://Graphics/Icons/atk.png")
var def_icon = preload("res://Graphics/Icons/def.png")
var acc_icon = preload("res://Graphics/Icons/acc.png")
var eva_icon = preload("res://Graphics/Icons/eva.png")
var w_1_1 = preload("res://Scenes/HX/Weapons/1_1.tscn")
var w_1_2 = preload("res://Scenes/HX/Weapons/1_2.tscn")
var w_1_3 = preload("res://Scenes/HX/Weapons/1_3.tscn")
var w_2_1 = preload("res://Scenes/HX/Weapons/2_1.tscn")
var w_2_2 = preload("res://Scenes/HX/Weapons/2_2.tscn")
var w_2_3 = preload("res://Scenes/HX/Weapons/2_3.tscn")
var w_3_1 = preload("res://Scenes/HX/Weapons/3_1.tscn")
var w_3_2 = preload("res://Scenes/HX/Weapons/3_2.tscn")
var w_3_3_1 = preload("res://Scenes/HX/Weapons/3_3_1.tscn")
var w_3_3_2 = preload("res://Scenes/HX/Weapons/3_3_2.tscn")

var star:Sprite#Shown right before HX magic

var ship_data# = [{"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
var HX_data
var HXs = []
var HX_c_d:Dictionary = {}#HX_custom_data
var w_c_d:Dictionary = {}#weapon_custom_data
var HX_w_c_d:Dictionary = {}#HX_weapon_custom_data
var a_p_c_d:Dictionary = {}#attack_pattern_custom_data
var curr_sh:int = 0#current_ship
var curr_en:int = 0#current_enemy
var weapon_type:String = ""#Type of weapon the player chose (bullet, laser etc.)
var immune:bool = false
var wave:int = 0
var weapon_XPs:Array = []
var tgt_sh:int = -1#target_ship
var hit_amount:int#Number of times your ships got hit (combined)

var victory_panel

enum BattleStages {CHOOSING, PLAYER, ENEMY}

var stage = BattleStages.CHOOSING

func _ready():
	Helper.set_back_btn($Back)
	randomize()
	if game:
		ship_data = game.ship_data
		HX_data = game.planet_data[game.c_p].HX_data
	else:
		HX_data = []
		ship_data = [{"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
		for k in 3:
			var lv = 1
			var HP = round(rand_range(1, 1.5) * 15 * pow(1.2, lv))
			var atk = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var def = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var acc = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var eva = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var money = round(rand_range(0.2, 2.5) * pow(1.2, lv) * 10000)
			var XP = round(pow(1.3, lv) * 5)
			HX_data.append({"type":Helper.rand_int(1, 2), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva, "money":money, "XP":XP})
	if OS.get_latin_keyboard_variant() == "AZERTY":
		$Help.text = "%s\n%s" % [tr("BATTLE_HELP") % ["Z", "M", "S", "ù", "Shift"], tr("PRESS_ANY_KEY_TO_CONTINUE")]
	else:
		$Help.text = "%s\n%s" % [tr("BATTLE_HELP") % ["W", ";", "S", "'", "Shift"], tr("PRESS_ANY_KEY_TO_CONTINUE")]
	stage = BattleStages.CHOOSING
	$Current/Current.float_height = 5
	$Current/Current.float_speed = 0.25
	for i in len(ship_data):
		get_node("Ship%s" % i).visible = true
		get_node("Ship%s/CollisionShape2D" % i).disabled = false
		weapon_XPs.append({"bullet":0, "laser":0, "bomb":0, "light":0})
		get_node("Ship%s/HP" % i).max_value = ship_data[i].total_HP
		get_node("Ship%s/HP" % i).value = ship_data[i].HP
		get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
	refresh_fight_panel()
	send_HXs()

func refresh_fight_panel():
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		get_node("FightPanel/HBox/%s/TextureRect" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), ship_data[0][weapon.to_lower()].lv])

func send_HXs():
	for j in 4:
		var k:int = j + wave * 4
		if k >= len(HX_data):
			break
		var btn = TextureButton.new()
		btn.rect_position = -Vector2(90, 50)
		btn.rect_size = Vector2(180, 100)
		var HX = HX1_scene.instance()
		HX.get_node("HX/Sprite").texture = load("res://Graphics/HX/%s.png" % [HX_data[k].type])
		HX.scale *= 0.4
		HX.get_node("HX/HP").max_value = HX_data[k].total_HP
		HX.get_node("HX/HP").value = HX_data[k].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[k].lv]
		HX.get_node("HX").set_script(load("res://Scripts/FloatAnim.gd"))
		HX.position = Vector2(2000, 360)
		HX.add_child(btn)
		btn.connect("mouse_entered", self, "on_HX_over", [k])
		btn.connect("mouse_exited", self, "on_HX_out")
		add_child(HX)
		HXs.append(HX)
		HX_c_d[HX.name] = {"knockback":Vector2.ZERO, "kb_dur":0, "kb_rot":0, "kb_spd":0, "position":Vector2((j % 2) * 300 + 850, (j / 2) * 150 + 250)}
	
func on_HX_over(id:int):
	if game:
		game.show_adv_tooltip("@i %s / %s\n@i %s   @i %s\n@i %s   @i %s" % [ceil(HX_data[id].HP), HX_data[id].total_HP, HX_data[id].atk, HX_data[id].def, HX_data[id].acc, HX_data[id].eva], [HP_icon, atk_icon, def_icon, acc_icon, eva_icon])

func on_HX_out():
	if game:
		game.hide_adv_tooltip()

var mouse_pos:Vector2 = Vector2.ZERO
func _input(event):
	Helper.set_back_btn($Back)
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	if stage == BattleStages.CHOOSING and Input.is_action_just_released("right_click"):
		remove_targets()
		$FightPanel.visible = true
	if Input.is_action_just_pressed("A"):
		display_stats("atk")
	if Input.is_action_just_pressed("D"):
		display_stats("def")
	if Input.is_action_just_pressed("C"):
		display_stats("acc")
	if Input.is_action_just_pressed("E"):
		display_stats("eva")
	if Input.is_action_just_pressed("H"):
		display_stats("HP")
	if Input.is_action_just_released("A") or Input.is_action_just_released("D") or Input.is_action_just_released("C") or Input.is_action_just_released("E") or Input.is_action_just_released("H"):
		for i in len(HXs):
			var HX = HXs[i]
			HX.get_node("Info/Icon").visible = false
			HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[i].lv]
		for i in len(ship_data):
			get_node("Ship%s/Icon" % i).visible = false
			get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
	if Input.is_action_just_pressed("battle_up"):
		ship_dir = "left"
	if Input.is_action_just_pressed("battle_down"):
		ship_dir = "right"
	if Input.is_action_just_released("battle_up") and Input.is_action_pressed("battle_down"):
		ship_dir = "right"
	elif Input.is_action_just_released("battle_up"):
		ship_dir = ""
	if Input.is_action_just_released("battle_down") and Input.is_action_pressed("battle_up"):
		ship_dir = "left"
	elif Input.is_action_just_released("battle_down"):
		ship_dir = ""
	if $Help.modulate.a == 1 and event is InputEventKey:
		game.help.battle = false
		$Help.modulate.a = 0
		tween.interpolate_property($Help, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5)
		tween.interpolate_property($Help, "rect_position", Vector2(0, 339), Vector2(0, 354), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
		tween.start()
		enemy_attack()

func display_stats(type:String):
	for i in len(HXs):
		var HX = HXs[i]
		HX.get_node("Info/Icon").visible = true
		HX.get_node("Info/Icon").texture = self["%s_icon" % [type]]
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [HX_data[i].HP, HX_data[i].total_HP]
		else:
			HX.get_node("Info/Label").text = String(HX_data[i][type])
	for i in len(ship_data):
		get_node("Ship%s/Icon" % i)
		get_node("Ship%s/Icon" % i).visible = true
		get_node("Ship%s/Icon" % i).texture = self["%s_icon" % [type]]
		if type == "HP":
			get_node("Ship%s/Label" % i).text = "%s / %s" % [ship_data[i].HP, ship_data[i].total_HP]
		else:
			get_node("Ship%s/Label" % i).text = String(ship_data[i][type])

func _on_Back_pressed():
	game.switch_view("system")

var ship_dir:String = ""

func damage_HX(id:int, dmg:float, crit:bool = false):
	HX_data[id].HP -= round(dmg)
	HXs[id].get_node("HX/HP").value = HX_data[id].HP
	Helper.show_dmg(round(dmg), HXs[id].position, self, 0.6, false, crit)

func hit_formula(acc:float, eva:float):
	return 1 / (1 + eva / pow(acc, 1.4))

func hitbox_size():
	if game:
		return 1 - (game.MUs.SHSR - 1) * 0.01
	else:
		return 0.5

func _process(delta):
	var battle_lost:bool = true
	for i in len(ship_data):
		if ship_data[i].HP <= 0:
			self["ship%s" % i].modulate.a = max(self["ship%s" % i].modulate.a - 0.03, 0)
		else:
			battle_lost = false
	if battle_lost:
		for i in len(ship_data):
			ship_data[i].HP = ship_data[i].total_HP
		game.switch_view("system")
		game.long_popup(tr("BATTLE_LOST_DESC"), tr("BATTLE_LOST"))
		return
	for i in len(HXs):
		var HX = HXs[i]
		if HX_data[i].HP <= 0 and HX.modulate.a > 0:
			HX.modulate.a -= 0.03
		var pos = HX_c_d[HX.name].position
		var kb_rot = HX_c_d[HX.name].kb_rot
		if HX_c_d[HX.name].knockback != Vector2.ZERO:
			var kb = HX_c_d[HX.name].knockback
			HX.position = HX.position.move_toward(pos + kb, HX.position.distance_to(pos + kb) * delta * 5)
			HX.rotation = move_toward(HX.rotation, kb_rot, kb_rot * delta)
			HX_c_d[HX.name].kb_dur -= delta
			if HX_c_d[HX.name].kb_dur < 0:
				HX_c_d[HX.name].knockback = Vector2.ZERO
		else:
			HX.rotation = move_toward(HX.rotation, 0, kb_rot * delta)
			HX.position = HX.position.move_toward(pos, HX.position.distance_to(pos) * delta * 5)
	if stage == BattleStages.CHOOSING:
		ship0.position = ship0.position.move_toward(Vector2(200, 200), ship0.position.distance_to(Vector2(200, 200)) * delta * 5)
		ship1.position = ship1.position.move_toward(Vector2(400, 200), ship1.position.distance_to(Vector2(400, 200)) * delta * 5)
		current.position = self["ship%s" % [curr_sh]].position + Vector2(0, -45)
		var hitbox_size:float = hitbox_size()
		for i in len(ship_data):
			if ship_data[i].HP <= 0:
				continue
			var ship_i = self["ship%s" % i]
			ship_i.scale = ship_i.scale.move_toward(Vector2.ONE, ship_i.scale.distance_to(Vector2.ONE) * delta * 5)
			ship_i.modulate.a = min(ship_i.modulate.a + 0.03, 1)
	elif stage == BattleStages.ENEMY:
		var hitbox_size:float = hitbox_size()
		for i in len(ship_data):
			var ship_i = self["ship%s" % i]
			if i == tgt_sh:
				ship_i.scale = ship_i.scale.move_toward(Vector2.ONE * hitbox_size, ship_i.scale.distance_to(Vector2.ONE * hitbox_size) * delta * 5)
				ship_i.position.x = move_toward(ship_i.position.x, 200, (abs(int(ship_i.position.x - 200))) * delta * 5)
				if ship_data[i].HP > 0:
					ship_i.modulate.a = min(ship_i.modulate.a + 0.03, 1)
			else:
				ship_i.scale = ship_i.scale.move_toward(Vector2.ONE, ship_i.scale.distance_to(Vector2.ONE) * delta * 5)
				ship_i.modulate.a = max(ship_i.modulate.a - 0.03, 0.2)
		var boost:int = 2.5 if Input.is_action_pressed("shift") or Input.is_action_pressed("X") else 1.1
		if ship_dir == "left":
			self["ship%s" % tgt_sh].position.y = max(0, self["ship%s" % tgt_sh].position.y - 10 * boost * delta * 60)
		elif ship_dir == "right":
			self["ship%s" % tgt_sh].position.y = min(720, self["ship%s" % tgt_sh].position.y + 10 * boost * delta * 60)
	for light in get_tree().get_nodes_in_group("lights"):
		light.scale += Vector2(0.1, 0.1)
		light.modulate.a -= 0.02
		if light.modulate.a <= 0:
			light.remove_from_group("lights")
			remove_child(light)
	for weapon in get_tree().get_nodes_in_group("weapon"):
		var sh:int = w_c_d[weapon.name].shooter
		weapon.position += w_c_d[weapon.name].v * delta * 60
		var remove_weapon_b:bool = weapon.position.x > 1350
		if weapon.position.x > w_c_d[weapon.name].lim and not w_c_d[weapon.name].has_hit:
			var w_data = "%s_data" % [weapon_type]
			var t = w_c_d[weapon.name].target
			if t == -1:
				remove_weapon_b = true
				var light = Sprite.new()
				light.texture = preload("res://Graphics/Decoratives/light.png")
				light.position = weapon.position
				light.scale *= 0.2
				light.modulate.a = 0.7
				add_child(light)
				light.add_to_group("lights")
				var light_hit:bool = false
				for i in len(HXs):
					if HX_data[i].HP <= 0:
						continue
					if randf() < hit_formula(ship_data[sh].acc * w_c_d[weapon.name].acc_mult, HX_data[i].eva):
						var dmg = ship_data[sh].atk * Data[w_data][ship_data[sh][weapon_type].lv - 1].damage / pow(HX_data[i].def, DEF_EXPO)
						var crit = randf() < 0.1
						if crit:
							dmg *= 1.5
						damage_HX(i, dmg, crit)
						light_hit = true
					else:
						Helper.show_dmg(0, HXs[i].position, self, 0.6, true)
				if light_hit:
					weapon_XPs[sh].light += 1
			else:
				if randf() < hit_formula(ship_data[sh].acc * w_c_d[weapon.name].acc_mult, HX_data[t].eva):
					var dmg = ship_data[sh].atk * Data[w_data][ship_data[sh][weapon_type].lv - 1].damage / pow(HX_data[w_c_d[weapon.name].target].def, DEF_EXPO)
					var crit = randf() < 0.1
					if crit:
						dmg *= 1.5
					damage_HX(t, dmg, crit)
					weapon_XPs[sh][weapon_type] += 1
					remove_weapon_b = true
				else:
					w_c_d[weapon.name].has_hit = true
					Helper.show_dmg(0, HXs[t].position, self, 0.6, true)
			$Timer.start()
		if remove_weapon_b:
			weapon.remove_from_group("weapon")
			remove_child(weapon)
	for weapon in get_tree().get_nodes_in_group("w_1_1"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if not HX_w_c_d[weapon.name].has("v"):
				HX_w_c_d[weapon.name].v = (weapon.position - self["ship%s" % tgt_sh].position) / 150.0
				weapon.visible = true
			weapon.position -= HX_w_c_d[weapon.name].v * delta * 60
			HX_w_c_d[weapon.name].v *= 0.07 * delta * 60 + 1
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_1_1")
	for weapon in get_tree().get_nodes_in_group("w_1_2"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.visible = true
				weapon.scale.y += 0.005 * delta * 60
				if weapon.scale.y > 0.2:
					HX_w_c_d[weapon.name].stage = 1
			elif HX_w_c_d[weapon.name].stage == 1:
				weapon.scale.y = 2
				weapon.modulate.a = 1
				HX_w_c_d[weapon.name].stage = 2
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].knockback = Vector2(35, 0)
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_dur = 0.5
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_spd = 2
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_rot = PI / 8
				weapon.get_node("CollisionShape2D").disabled = false
			elif HX_w_c_d[weapon.name].stage == 2:
				weapon.modulate.a -= 0.02 * delta * 60
				if weapon.modulate.a <= 0:
					remove_weapon(weapon, "w_1_2")
	for weapon in get_tree().get_nodes_in_group("w_1_3"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.visible = true
				weapon.position = weapon.position.move_toward(HX_w_c_d[weapon.name].target, weapon.position.distance_to(HX_w_c_d[weapon.name].target) * delta * 5)
				if HX_w_c_d[weapon.name].delay < -1:
					HX_w_c_d[weapon.name].stage = 1
				if HX_w_c_d[weapon.name].delay < -0.3:
					weapon.rotation = move_toward(weapon.rotation, 0, 0.12)
			else:
				weapon.position += HX_w_c_d[weapon.name].v * delta * 60
				HX_w_c_d[weapon.name].v *= 0.02 * delta * 60 + 1
				if weapon.position.x < -100:
					remove_weapon(weapon, "w_1_3")
	for weapon in get_tree().get_nodes_in_group("w_2_1"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position.x -= 14 * delta * 60
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_2_1")
	for weapon in get_tree().get_nodes_in_group("w_2_2"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.position.y = move_toward(weapon.position.y, HX_w_c_d[weapon.name].y_target, abs(HX_w_c_d[weapon.name].y_target - weapon.position.y) * delta * 4)
				if HX_w_c_d[weapon.name].delay < -1.2:
					HX_w_c_d[weapon.name].stage = 1
			else:
				weapon.position -= (Vector2(HX_w_c_d[weapon.name].init_x, HX_w_c_d[weapon.name].y_target) - Vector2(-100, HX_w_c_d[weapon.name].y_target2)) * delta * 0.8
				if weapon.position.x < -100:
					remove_weapon(weapon, "w_2_2")
	for weapon in get_tree().get_nodes_in_group("w_2_3"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position += HX_w_c_d[weapon.name].v * delta * 60
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_2_3")
	for weapon in get_tree().get_nodes_in_group("w_3_1"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.visible = true
			weapon.position += HX_w_c_d[weapon.name].v * delta * 60
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_3_1")
	if a_p_c_d.has("pattern") and a_p_c_d.pattern == "3_1":
		a_p_c_d.delay -= delta
		HX_c_d[HXs[a_p_c_d.HX_id].name].position.y = a_p_c_d.y_poses[a_p_c_d.i]
		if a_p_c_d.delay < 0:
			a_p_c_d.delay = 0.8
			if a_p_c_d.i >= len(a_p_c_d.y_poses) - 1:
				a_p_c_d.clear()
			else:
				a_p_c_d.i += 1
	for weapon in get_tree().get_nodes_in_group("w_3_2"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position -= Vector2(10, 0) * delta * 60
			if weapon.position.x < 300:
				weapon.get_node("CollisionPolygon2D").disabled = false
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_3_2")
	for weapon in get_tree().get_nodes_in_group("w_3_3"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position.x -= 5 * delta * 60
			if HX_w_c_d[weapon.name].has("vy"):
				HX_w_c_d[weapon.name].delay2 -= delta
				if HX_w_c_d[weapon.name].delay2 < 0:
					weapon.visible = true
					weapon.position.y += HX_w_c_d[weapon.name].vy * delta * 60
			if weapon.position.x < -150 or weapon.position.y < -20 or weapon.position.y > 740:
				remove_weapon(weapon, "w_3_3")
	if star:
		star.scale += Vector2(0.12, 0.12) * delta * 60
		star.modulate.a -= 0.03 * delta * 60
		star.rotation += 0.04 * delta * 60
		if star.modulate.a <= 0:
			remove_child(star)
			star = null

func remove_weapon(weapon, group:String):
	weapon.remove_from_group(group)
	remove_child(weapon)
	if get_tree().get_nodes_in_group(group).empty():
		$Timer.start()

func remove_targets():
	for target in get_tree().get_nodes_in_group("targets"):
		target.remove_from_group("targets")
		remove_child(target)
	for HX in HXs:
		HX.get_node("HX").modulate.a = 1

func place_targets():
	remove_targets()
	var target_id:int = -1
	for i in len(HXs):
		if HX_data[i].HP <= 0:
			continue
		if target_id == -1:#A way to not show target buttons if there's only one target alive
			target_id = i
		else:
			target_id = -2
		var HX = HXs[i]
		HX.get_node("HX").modulate.a = 0.5
		var target = target_scene.instance()
		target.position = HX.position
		add_child(target)
		target.get_node("TextureButton").shortcut = ShortCut.new()
		target.get_node("TextureButton").shortcut.shortcut = InputEventAction.new()
		target.get_node("TextureButton").shortcut.shortcut.action = String((i % 4) + 1)
		target.get_node("TextureButton").connect("pressed", self, "on_target_pressed", [i])
		target.get_node("Label").text = String((i % 4) + 1)
		target.add_to_group("targets")
	if target_id != -2:
		on_target_pressed(target_id)

func on_target_pressed(target:int):
	var weapon_data = ship_data[curr_sh][weapon_type]
	$FightPanel.visible = false
	$Current.visible = false
	$Back.visible = false
	stage = BattleStages.PLAYER
	var weapon = Sprite.new()
	weapon.add_to_group("weapon")
	weapon.texture = load("res://Graphics/Weapons/%s%s.png" % [weapon_type, weapon_data.lv])
	var ship_pos = self["ship%s" % [curr_sh]].position
	weapon.position = ship_pos
	weapon.scale *= 0.5
	add_child(weapon)
	var HX_pos = Vector2(1000, 360) if target == -1 else HXs[target].position 
	weapon.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
	w_c_d[weapon.name] = {"v":(HX_pos - ship_pos) / 30.0}
	w_c_d[weapon.name].target = target
	w_c_d[weapon.name].shooter = curr_sh
	w_c_d[weapon.name].lim = HX_pos.x
	w_c_d[weapon.name].acc_mult = Data["%s_data" % [weapon_type]][weapon_data.lv - 1].accuracy
	w_c_d[weapon.name].has_hit = false
	remove_targets()
	curr_sh += 1

func _on_weapon_pressed(_weapon_type:String):
	weapon_type = _weapon_type
	$FightPanel.visible = false
	if weapon_type == "light":
		on_target_pressed(-1)
	else:
		place_targets()

func _on_Timer_timeout():
	var HXs_rekt:int = wave * 4
	while curr_en < len(HX_data) and HX_data[curr_en].HP <= 0:
		HXs_rekt += 1
		curr_en += 1
	if HXs_rekt >= len(HX_data):
		victory_panel = victory_panel_scene.instance()
		victory_panel.HX_data = HX_data
		victory_panel.ship_data = ship_data
		victory_panel.weapon_XPs = weapon_XPs
		victory_panel.rect_position = Vector2(108, 60)
		victory_panel.p_id = game.c_p
		if hit_amount == 0:
			victory_panel.mult = 1.5
		elif hit_amount == 1:
			victory_panel.mult = 1.25
		elif hit_amount == 2:
			victory_panel.mult = 1.1
		else:
			victory_panel.mult = 1
		add_child(victory_panel)
		return
	if HXs_rekt >= (wave + 1) * 4:
		wave += 1
		send_HXs()
		curr_sh = 0
		curr_en = wave * 4
		stage = BattleStages.CHOOSING
		$FightPanel.visible = true
		refresh_fight_panel()
		$Current.visible = true
		$Back.visible = true
	else:
		if curr_sh >= len(ship_data):
			stage = BattleStages.ENEMY
			$Timer.wait_time = 0.2
			tgt_sh = Helper.rand_int(1, len(ship_data)) - 1
			while ship_data[tgt_sh].HP <= 0:
				tgt_sh = Helper.rand_int(1, len(ship_data)) - 1
			enemy_attack()
		else:
			curr_en = wave * 4
			stage = BattleStages.CHOOSING
			$FightPanel.visible = true
			refresh_fight_panel()
			$Current.visible = true
			$Back.visible = true

var tween:Tween
func enemy_attack():
	if game and game.help.battle:
		tween = Tween.new()
		add_child(tween)
		$Help.modulate.a = 0
		$Help.visible = true
		tween.interpolate_property($Help, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.5)
		tween.interpolate_property($Help, "rect_position", Vector2(0, 354), Vector2(0, 339), 0.5)
		tween.start()
	else:
		if curr_en == min((wave + 1) * 4, len(HX_data)):
			curr_sh = 0
			curr_en = wave * 4
			stage = BattleStages.CHOOSING
			$Timer.wait_time = 1.0
			$FightPanel.visible = true
			$Back.visible = true
			$Current.visible = true
		else:
			call("atk_%s_%s" % [HX_data[curr_en].type, Helper.rand_int(1, 3)], curr_en)
			curr_en += 1

func put_magic(id:int):
	star = Sprite.new()
	star.texture = preload("res://Graphics/Decoratives/Star2.png")
	star.position = HXs[id].position - Vector2(0, 15)
	star.scale *= 0.5
	add_child(star)

func atk_1_1(id:int):
	for i in 10:
		var fireball = w_1_1.instance()
		fireball.position = HXs[id].position
		fireball.visible = false
		fireball.add_to_group("w_1_1")
		add_child(fireball)
		HX_w_c_d[fireball.name] = {"group":"w_1_1", "damage":5, "id":id, "delay":i * 0.3}

func atk_1_2(id:int):
	for i in 4:
		var y_pos:int = 0
		for j in 2:
			var beam = w_1_2.instance()
			var target:Vector2 = Vector2(0, rand_range(0, 720))
			if j == 0:
				y_pos = target.y
			else:
				while abs(target.y - y_pos) < 200:
					target.y = rand_range(0, 720)
			var pos = HXs[id].position
			beam.position = pos
			beam.rotation = atan2(pos.y - target.y, pos.x - target.x)
			beam.visible = false
			beam.scale.x = 4
			beam.modulate.a = 0.5
			beam.scale.y = 0
			beam.get_node("CollisionShape2D").disabled = true
			beam.add_to_group("w_1_2")
			add_child(beam)
			HX_w_c_d[beam.name] = {"group":"w_1_2", "damage":6, "stage":0, "id":id, "delay":i * 1.2}

func atk_1_3(id:int):
	for i in 5:
		for j in 18:
			var bullet = w_1_3.instance()
			var target:Vector2 = Vector2(1100, rand_range(0, 720))
			var pos = HXs[id].position
			bullet.position = pos
			bullet.rotation = atan2(pos.y - target.y, pos.x - target.x)
			bullet.visible = false
			bullet.scale *= 0.8
			bullet.add_to_group("w_1_3")
			add_child(bullet)
			HX_w_c_d[bullet.name] = {"group":"w_1_3", "v":Vector2(-1, 0), "target":target, "damage":4.5, "stage":0, "id":id, "delay":i * 0.8}

func atk_2_1(id:int):
	put_magic(id)
	for i in 8:
		var pillar = w_2_1.instance()
		if i % 2 == 0:
			pillar.scale.y *= -1
			pillar.position.y = rand_range(-50, 260)
		else:
			pillar.position.y = rand_range(460, 770)
		pillar.position.x = 1400
		add_child(pillar)
		pillar.add_to_group("w_2_1")
		HX_w_c_d[pillar.name] = {"group":"w_2_1", "damage":6, "id":id, "delay":i * 0.5 + 0.5}

func atk_2_2(id:int):
	put_magic(id)
	for i in 18:
		var ball = w_2_2.instance()
		if i % 2 == 0:
			ball.position.y = -200
		else:
			ball.position.y = 920
		var y_target = rand_range(280, 440)
		var y_target2 = rand_range(-50, 770)
		while abs(y_target2 - y_target) < 100:
			y_target2 = rand_range(-50, 770)
		ball.position.x = rand_range(900, 1250)
		add_child(ball)
		ball.add_to_group("w_2_2")
		HX_w_c_d[ball.name] = {"group":"w_2_2", "init_x":ball.position.x, "y_target":y_target, "y_target2":y_target2, "stage":0, "damage":5.5, "id":id, "delay":i * 0.25 + 0.5}

func atk_2_3(id:int):
	put_magic(id)
	for i in 40:
		var mine = w_2_3.instance()
		var v:Vector2 = Vector2(-8, rand_range(0, 6))
		mine.position = Vector2(1350, rand_range(0, 720))
		mine.scale *= rand_range(0.6, 0.9)
		if mine.position.y > 360:
			v.y *= -1
		v *= 1.8 - mine.scale.x
		mine.rotation = rand_range(0, 2 * PI)
		add_child(mine)
		mine.add_to_group("w_2_3")
		HX_w_c_d[mine.name] = {"group":"w_2_3", "v":v, "damage":4.5, "id":id, "delay":i * 0.15 + 0.5}

func atk_3_1(id:int):
	a_p_c_d.clear()
	var y_poses = []
	for i in 6:
		var y_pos = rand_range(100, 620)
		y_poses.append(y_pos)
		var proj_num:int = 7 if id % 2 == 0 else 11
		var spread:float = 0.2 if id % 2 == 0 else 0.13
		for j in proj_num:
			var spike = w_3_1.instance()
			spike.rotation = (j - proj_num / 2) * spread
			spike.position = Vector2(HXs[id].position.x, y_pos)
			var v = -Vector2(cos(spike.rotation), sin(spike.rotation)) * 8
			spike.visible = false
			add_child(spike)
			spike.add_to_group("w_3_1")
			HX_w_c_d[spike.name] = {"group":"w_3_1", "id":id, "v":v, "damage":5, "delay":i * 0.8 + 0.5}
	y_poses.append(HXs[id].position.y)
	a_p_c_d = {"pattern":"3_1", "HX_id":id, "y_poses":y_poses, "i":0, "delay":0.8}

func atk_3_2(id:int):
	put_magic(id)
	var path:int = Helper.rand_int(0, 12)
	var dir = rand_range(0.1, 0.9)
	while abs(dir - 0.5) < 0.2:
		dir = rand_range(0.1, 0.9)
	var dir_bool = true
	for i in 50:
		for j in 16:
			if j >= path and j <= path + 4:
				continue
			var diamond = w_3_2.instance()
			diamond.position = Vector2(1350 + i * 48, j * 48)
			diamond.get_node("CollisionPolygon2D").disabled = true
			add_child(diamond)
			diamond.add_to_group("w_3_2")
			diamond.modulate = Color(rand_range(0.5, 1), rand_range(0.5, 1), rand_range(0.5, 1), 1)
			HX_w_c_d[diamond.name] = {"group":"w_3_2", "id":id, "damage":4.8, "delay":0.5}
		if randf() < 0.6:
			if dir_bool and randf() < dir or not dir_bool and randf() > dir:
				path -= 1
				if path < 0:
					dir_bool = not dir_bool
					path = 1
			else:
				path += 1
				if path > 12:
					dir_bool = not dir_bool
					path = 12

func atk_3_3(id:int):
	put_magic(id)
	for i in 3:
		var platform = w_3_3_1.instance()
		platform.position = Vector2(1400, rand_range(200, 520))
		add_child(platform)
		platform.add_to_group("w_3_3")
		var platform_delay:float = i * 1.5 + 0.5
		HX_w_c_d[platform.name] = {"group":"w_3_3", "id":id, "damage":10, "delay":platform_delay}
		var interval:float = rand_range(0.65, 0.7)
		for j in 14:
			var bullet = w_3_3_2.instance()
			bullet.position = Vector2(1400, platform.position.y)
			bullet.visible = false
			add_child(bullet)
			bullet.add_to_group("w_3_3")
			HX_w_c_d[bullet.name] = {"group":"w_3_3", "vy":3 if j % 2 == 0 else -3, "id":id, "damage":4.5, "delay":platform_delay, "delay2":interval * (j / 2)}

func _on_Ship_area_entered(area, ship_id:int):
	if immune or self["ship%s" % ship_id].modulate.a != 1.0:
		return
	var HX = HX_data[HX_w_c_d[area.name].id]
	if randf() < hit_formula(HX.acc, ship_data[ship_id].eva):
		var dmg:int = HX_w_c_d[area.name].damage * HX.atk / pow(ship_data[ship_id].def, DEF_EXPO)
		Helper.show_dmg(dmg, self["ship%s" % ship_id].position, self, 0.6)
		ship_data[ship_id].HP -= dmg
	else:
		Helper.show_dmg(0, self["ship%s" % ship_id].position, self, 0.6, true)
	$ImmuneTimer.start()
	hit_amount += 1
	immune = true
	if not HX_w_c_d[area.name].group in ["w_1_2", "w_2_1", "w_3_3"]:
		remove_weapon(area, HX_w_c_d[area.name].group)
	get_node("Ship%s/HP" % [ship_id]).value = ship_data[ship_id].HP

func _on_ImmuneTimer_timeout():
	immune = false

func _on_Battle_tree_exited():
	queue_free()

func _on_weapon_mouse_entered(weapon:String):
	if game:
		var w_lv:int = ship_data[curr_sh][weapon].lv
		game.show_tooltip("%s %s %s\n%s: %s\n%s: %s" % [tr(weapon.to_upper()), tr("LV"), w_lv, tr("BASE_DAMAGE"), Data["%s_data" % [weapon]][w_lv - 1].damage, tr("BASE_ACCURACY"), Data["%s_data" % [weapon]][w_lv - 1].accuracy])

func _on_weapon_mouse_exited():
	if game:
		game.hide_tooltip()
