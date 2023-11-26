extends Node2D


var fileName="Map/Map/Map0/000010000.json"
var file=FileAccess.open(fileName,FileAccess.READ)
var json=JSON.parse_string(file.get_as_text())
	#print(json['Layers'][0]['Tiles'])

# Called when the node enters the scene tree for the first time.
func _ready():
	var camera2d=Camera2D.new()
	add_child(camera2d)
	var i=0
	for layers in json['Layers']:
		if layers['Tiles']!=null:
			for tile in layers['Tiles']:
				var node = Sprite2D.new()
				node.set_texture(load("res://"+tile['Resource']['ResourceUrl']))
				node.set_centered(false)
				node.set_position(Vector2(tile['X'], tile['Y']))
				node.set_offset(Vector2(-tile['Resource']['OriginX'], -tile['Resource']['OriginY']))
				node.set_z_index(composite_zindex(i,tile['Resource']['Z'],tile['ID'],0))
				camera2d.add_child(node)
		i=i+1
	pass # Replace with function body.
	var staticBody2D=StaticBody2D.new()
	var collisionShape2D=CollisionShape2D.new()
	staticBody2D.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func normalize(z):
	var scale = 16;
	z = z+ scale/2
	z = max(0, min(z, scale - 1));
	return z;

func composite_zindex(z, z0, z1, z2):
	var scale = 16
	return ((normalize(z) * scale * scale * scale
		+ normalize(z0) * scale * scale
		+ normalize(z1) * scale
		+ normalize(z2)))/100;
