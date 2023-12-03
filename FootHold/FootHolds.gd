extends Node
class_name FootHolds;

static var limit_left=0
static var limit_right=0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _init(parent,foothold,layer):
	var staticBody2D=StaticBody2D.new()
	var segmentShape2D=SegmentShape2D.new()
	var a=Vector2(foothold['X1'],foothold['Y1'])
	var b=Vector2(foothold['X2'],foothold['Y2'])
	var collisionShape2D=CollisionShape2D.new()
	collisionShape2D.set_one_way_collision(true)
	match get_foothold_type(a,b):
		#因为单边碰撞需要靠旋转来完成,所有先旋转到角度后再转回来
		Common.FootHoldType.UP:
			a=a.rotated(deg_to_rad(0))
			b=b.rotated(deg_to_rad(0))
			collisionShape2D.set_rotation_degrees(0)
		Common.FootHoldType.DOWN:
			a=a.rotated(deg_to_rad(-180))
			b=b.rotated(deg_to_rad(-180))
			collisionShape2D.set_rotation_degrees(180)
		Common.FootHoldType.LEFT:
			a=a.rotated(deg_to_rad(-90))
			b=b.rotated(deg_to_rad(-90))
			collisionShape2D.set_rotation_degrees(90)
		Common.FootHoldType.RIGHT:
			a=a.rotated(deg_to_rad(-270))
			b=b.rotated(deg_to_rad(-270))
			collisionShape2D.set_rotation_degrees(270)
	segmentShape2D.set_a(a)
	segmentShape2D.set_b(b)
	collisionShape2D.set_shape(segmentShape2D)
	staticBody2D.set_meta("layer",layer)
	if foothold['X1']==foothold['X2']:
		staticBody2D.set_meta("type","wall")
	else:
		staticBody2D.set_meta("type","floor")
	staticBody2D.add_child(collisionShape2D)
	staticBody2D.collision_layer=pow(2, layer)
	
	limit_left = min(foothold['X1'], foothold['X2'],limit_left)
	limit_right = max(foothold['X1'], foothold['X2'], limit_right)
	parent.add_child(staticBody2D)
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.


#线段绘制方向决定了单边碰撞的方向
#水平线段如果是从左往右画，那么从上往下移动会发生碰撞，从下往上移动不会发生碰撞--GruopA
#水平线段如果是从右往左画，那么从下往上移动会发生碰撞，从上往下移动不会发生碰撞--GruopB
#垂直线段如果是从上往下画，那么从右往左移动会发生碰撞，从左往右移动不会发生碰撞--GruopC
#垂直线段如果是从下往上画，那么从左往右移动会发生碰撞，从右往左移动不会发生碰撞--GruopD
#所有斜线只有从上往下会发生碰撞
#
#当某条垂直线段往下延伸的其他线段都是垂直线段，且没有出现拐弯就突然中断时，那么这条线段是无效的墙，永远不会发生碰撞
#
#当角色处于地面的时候，只能与相同layer的线段发生碰撞
#当角色处于空中的时候，能与所有非垂直线段发生碰撞，但是只能与相同layer的垂直线段发生碰撞

func get_foothold_type(a,b):
	if a.y==b.y:
		if a.x<b.x:
			return Common.FootHoldType.UP
		else:
			return Common.FootHoldType.DOWN
	if a.x==b.x:
		if a.y<b.y:
			return Common.FootHoldType.LEFT
		else :
			return Common.FootHoldType.RIGHT
	return Common.FootHoldType.UP
	
