extends Node2D

var camera:Camera2D;
var fileName="Map/Map/Map0/000010000.json"
var file=FileAccess.open(fileName,FileAccess.READ)
#var json
var json=JSON.parse_string(file.get_as_text())


# Called when the node enters the scene tree for the first time.
func _ready():	
	#json=JSON.parse_string(Wz.Test())
	#print(Wz.Test()) #调用wz的dll解析
	var limit_left = 0 #Tile左边界
	var limit_right = 0 #Tile右边界
	#创建FootHold,不用判断非空,因为地图是一定有fh
	for mapFootHold in json['FootHolds']:
		var layer=mapFootHold['Layer']
		for foothold in mapFootHold['FootHolds']:
			FootHolds.new(self,foothold,layer)
	limit_left=FootHolds.limit_left
	limit_right=FootHolds.limit_right
	#地图左右边界
	for i in [limit_left,limit_right]:
		var staticBody2D=StaticBody2D.new()
		staticBody2D.set_meta("type","wall")
		var segmentShape2D=SegmentShape2D.new()
		segmentShape2D.set_a(Vector2(i,-10000000))
		segmentShape2D.set_b(Vector2(i,10000000))
		var collisionShape2D=CollisionShape2D.new()
		collisionShape2D.set_shape(segmentShape2D)
		staticBody2D.add_child(collisionShape2D)
		staticBody2D.collision_mask=0
		staticBody2D.collision_layer=0
		staticBody2D.collision_mask=Common.ALL_MASK
		staticBody2D.collision_layer=Common.ALL_MASK
		add_child(staticBody2D)
	
	
	#生成人物
	var characterBody2D=CharacterBody2D.new()
	characterBody2D.set_floor_snap_length(20)
	var sprite=Sprite2D.new()
	sprite.set_texture(load("res://icon.svg"))
	sprite.set_scale(Vector2(0.25,0.25))
	var collisionShape2D=CollisionShape2D.new()
	var rectangleShape2D=RectangleShape2D.new()
	rectangleShape2D.set_size(Vector2(32,32))
	collisionShape2D.set_shape(rectangleShape2D)
	var camera2d=Camera2D.new()
	camera2d.set_position_smoothing_enabled(true)
	characterBody2D.add_child(sprite)
	characterBody2D.add_child(collisionShape2D)
	characterBody2D.add_child(camera2d)
	characterBody2D.set_script(load("res://Player/Player.gd"))
	add_child(characterBody2D)
	#生成地图layers
	for i in range(0,json['Layers'].size()):
		var layers=json['Layers'][i]
		if layers['Tiles']!=null:
			for tile in layers['Tiles']:
				var node = Sprite2D.new()
				node.set_texture(load("res://"+tile['Resource']['ResourceUrl']))
				node.set_centered(false)
				node.set_position(Vector2(tile['X'], tile['Y']))
				node.set_offset(Vector2(-tile['Resource']['OriginX'], -tile['Resource']['OriginY']))
				node.set_z_index(Common.composite_zindex(i,tile['Resource']['Z'],tile['ID'],0))
				add_child(node)
				
	camera2d.limit_left=limit_left
	camera2d.limit_right=limit_right
	
	for i in range(0,json['Layers'].size()):
		var layers=json['Layers'][i]
		if layers['Objs']!=null:
			for obj in layers['Objs']:
				var o=Objs.new(self,obj,i)
				pass
	
	#地图背景及跟随
	var layerNode=CanvasLayer.new()
	for i in range(0,json['Backs'].size()):
		var backs=json['Backs'][i]
		if backs!=null:
			var b=Backs.new(self,backs)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

