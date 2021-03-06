extends Node2D

onready var game = self.get_parent().get_parent()
onready var view = self.get_parent()
var btns = []

func _ready():
	for c_i in game.cluster_data:
		var cluster_btn = TextureButton.new()
		var cluster = Sprite.new()
		var cluster_texture = load("res://Graphics/Clusters/" + String(c_i["type"]) + ".png")
		cluster_btn.texture_normal = cluster_texture
		self.add_child(cluster)
		cluster.add_child(cluster_btn)
		cluster_btn.connect("mouse_entered", self, "on_cluster_over", [c_i.l_id])
		cluster_btn.connect("mouse_exited", self, "on_cluster_out")
		cluster_btn.connect("pressed", self, "on_cluster_click", [c_i.id, c_i.l_id])
		cluster_btn.rect_position = Vector2(-640 / 2, -640 / 2)
		cluster_btn.rect_pivot_offset = Vector2(640 / 2, 640 / 2)
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.5) * view.scale_mult
		cluster_btn.rect_scale.x = radius
		cluster_btn.rect_scale.y = radius
		cluster.position = c_i["pos"]
		btns.append(cluster_btn)

func on_cluster_over (id:int):
	var c_i = game.cluster_data[id]
	game.show_tooltip("%s\n%s: %s\n%s: %s" % [c_i.name, tr("GALAXIES"), c_i.galaxy_num, tr("DIFFICULTY"), c_i.diff])

func on_cluster_out ():
	game.hide_tooltip()

func on_cluster_click (id:int, l_id:int):
	if not view.dragged:
		game.c_c_g = id
		game.c_c = l_id
		game.switch_view("cluster")

var change_alpha = 0.05
func _process(_delta):
	if modulate.a < 1:
		modulate.a += change_alpha
	if modulate.a <= 0:
		game.hide_tooltip()
		for i in range(0, btns.size()):
			var radius = pow(game.cluster_data[i]["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.5) * view.scale_mult
			btns[i].rect_scale.x = radius
			btns[i].rect_scale.y = radius
		change_alpha *= -1
		modulate.a = change_alpha


func _on_Cluster_tree_exited():
	queue_free()
