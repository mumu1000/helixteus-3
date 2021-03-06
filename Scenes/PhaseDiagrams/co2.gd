extends Node2D

func _ready():
	place(194, 1, $MeltPoint)
	place(216, 5.11, $TriplePoint)
	place(304, 73.9, $SuperPoint)

var colors = {	"S":Color(0.88, 0.66, 0.3, 0.7),
				"L":Color(0.88, 0.66, 0.3, 1.0),
				"SC":Color(0.88, 0.66, 0.3, 0.4)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
