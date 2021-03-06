extends KinematicBody2D

var velocity:Vector2 = Vector2.ZERO
var texture
var damage
var enemy:bool
var cave_ref

func _ready():
	$Sprite.texture = texture

func _physics_process(_delta):
	var target_coll:KinematicCollision2D = move_and_collide(velocity)
	if target_coll != null:
		var target = target_coll.get_collider()
		if target is KinematicBody2D:
			if not enemy:
				var dmg_penalty:float = max(1, position.distance_to(cave_ref.rover.position) / 300.0)
				var dmg:float = damage / dmg_penalty / pow(target.def, cave_ref.DEF_EXPO)
				Helper.show_dmg(int(dmg), target_coll.position, cave_ref)
				target.hit(dmg)
			else:
				var dmg:float = damage / pow(cave_ref.def, cave_ref.DEF_EXPO)
				cave_ref.hit_player(dmg)
				if cave_ref.HP >= 0:
					Helper.show_dmg(int(dmg), target_coll.position, cave_ref)
		get_parent().remove_child(self)
