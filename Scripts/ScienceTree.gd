extends Node2D

onready var game = get_node('/root/Game')
var sc_over:String = ""

func _ready():
	yield(get_tree().create_timer(0), "timeout")
	refresh()

func refresh():
	for sc in get_children():
		if sc is Line2D or not Data.science_unlocks.has(sc.name):
			continue
		var p_scs:Array = Data.science_unlocks[sc.name].parents
		if sc.get_script():#A way of checking whether the node is a button
			sc.main_tree = self
			#parent_science
			if p_scs.empty():
				continue
			var available:bool = true
			for p_sc in p_scs:
				if not game.science_unlocked[p_sc]:
					available = false
					break
			if available:
				sc.modulate = Color.white
				sc.get_node("Texture").modulate = Color.white
				sc.mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				sc.modulate = Color(0.5, 0.5, 0.5, 1)
				sc.get_node("Texture").modulate = Color.black
				sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sc.refresh()
