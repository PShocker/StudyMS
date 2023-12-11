extends Node2D

var camera:Camera2D;
#var fileName="Map/Map/Map0/000010000.json"
#var file=FileAccess.open(fileName,FileAccess.READ)
#var json=JSON.parse_string(file.get_as_text())
var json

# Called when the node enters the scene tree for the first time.
func _ready():	
	#print(Wz.Test())
	json=JSON.parse_string(Wz.Test())
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
		staticBody2D.collision_mask=pow(2,32)-1
		staticBody2D.collision_layer=pow(2,32)-1
		add_child(staticBody2D)
	
	
	#生成人物
	var player=Player.new(self,limit_left,limit_right)
	#生成地图layers
	for i in range(0,json['Layers'].size()):
		var layers=json['Layers'][i]
		if layers['Tiles']!=null:
			for tile in layers['Tiles']:
				var node = Sprite2D.new()
				var image := Image.new()
				node.set_texture(Common.get_resource(tile['Resource']['ResourceUrl']))
				node.set_centered(false)
				node.set_position(Vector2(tile['X'], tile['Y']))
				node.set_offset(Vector2(-tile['Resource']['OriginX'], -tile['Resource']['OriginY']))
				node.set_z_index(Common.composite_zindex(i,tile['Resource']['Z'],tile['ID'],0))
				add_child(node)
				
	
	
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

