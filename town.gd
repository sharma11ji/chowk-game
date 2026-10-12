extends Node2D
## Entirely original primitive art. Gameplay is independent of the illustration.
const CELL := 12
const SPEED := 190.0
const WORLD := Rect2(24, 154, 672, 920)
const INK := Color("253b38")
const SAND := Color("dfcfac")
const ROAD := Color("696f6b")
const CREAM := Color("fff1ce")
var font: Font = ThemeDB.fallback_font
var player: CharacterBody2D
var nav := AStarGrid2D.new()
var path := PackedVector2Array()
var target := Vector2.ZERO
var has_target := false
var pad_touch := -1
var pad_dir := Vector2.ZERO
var step_clock := 0.0
var moving := false
var facing := Vector2.DOWN
var nearby := "Apna mohalla"
var buildings: Array[Dictionary] = [
 {"rect":Rect2(48,226,216,144),"name":"CHAI TAPRI","sub":"Raju ki chai","color":Color("be6845"),"kind":"chai"},
 {"rect":Rect2(456,226,216,166),"name":"KIRANA STORE","sub":"Gupta general store","color":Color("568580"),"kind":"store"},
 {"rect":Rect2(58,470,190,139),"name":"SHARMA NIWAS","sub":"","color":Color("c18d61"),"kind":"house"},
 {"rect":Rect2(470,466,192,146),"name":"VERMA HOUSE","sub":"","color":Color("94a379"),"kind":"house"},
 {"rect":Rect2(54,834,192,146),"name":"GALI NO. 1","sub":"","color":Color("b18480"),"kind":"house"},
 {"rect":Rect2(474,844,192,142),"name":"GALI NO. 2","sub":"","color":Color("779394"),"kind":"house"}
]
var obstacles: Array[Rect2] = []
var npcs := [{"pos":Vector2(222,415),"name":"Raju","shirt":Color("e5bb61")},{"pos":Vector2(499,419),"name":"Gupta ji","shirt":Color("f7e6c0")}]

func _ready() -> void:
 player = CharacterBody2D.new()
 player.name = "Player"
 var col := CollisionShape2D.new()
 var shape := CircleShape2D.new()
 shape.radius = 11
 col.shape = shape
 player.add_child(col)
 add_child(player)
 player.position = Vector2(360,790)
 for b in buildings:
  add_obstacle(b.rect)
 # Solid tree trunks and cart, not just buildings.
 for p in [Vector2(112,718),Vector2(601,727),Vector2(153,1030),Vector2(585,1034)]:
  add_obstacle(Rect2(p-Vector2(10,10),Vector2(20,20)))
 add_obstacle(Rect2(462,661,100,55))
 # World boundary is real collision, not an invisible teleport clamp.
 add_obstacle(Rect2(0,130,720,24))
 add_obstacle(Rect2(0,1074,720,24))
 add_obstacle(Rect2(0,154,24,920))
 add_obstacle(Rect2(696,154,24,920))
 nav.region = Rect2i(0,0,60,107)
 nav.cell_size = Vector2(CELL,CELL)
 nav.offset = Vector2(6,6)
 nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 nav.update()
 for y in range(107):
  for x in range(60):
   var p := nav.get_point_position(Vector2i(x,y))
   var solid := not WORLD.grow(-12).has_point(p)
   for r in obstacles:
    if r.grow(15).has_point(p): solid = true
   nav.set_point_solid(Vector2i(x,y),solid)
 for arg in OS.get_cmdline_user_args():
  if arg == "--pose=chai": player.position = Vector2(257,427)
  if arg == "--pose=kirana": player.position = Vector2(445,424)
 queue_redraw()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture="):
   capture.call_deferred(arg.substr(10))

func add_obstacle(r: Rect2) -> void:
 obstacles.append(r)
 var body := StaticBody2D.new()
 var col := CollisionShape2D.new()
 var shape := RectangleShape2D.new()
 shape.size = r.size
 col.shape = shape
 body.position = r.get_center()
 body.add_child(col)
 add_child(body)

func capture(filename: String) -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var img := get_viewport().get_texture().get_image()
 print("CAPTURE: ",img.save_png(filename)," ",filename)
 get_tree().quit()

func request_move(p: Vector2) -> bool:
 if not WORLD.grow(-13).has_point(p): return false
 var goal := Vector2i(floor(p.x/CELL),floor(p.y/CELL))
 var start := Vector2i(floor(player.position.x/CELL),floor(player.position.y/CELL))
 if nav.is_point_solid(goal): return false
 path = nav.get_point_path(start,goal)
 if path.is_empty(): return false
 target = p
 has_target = true
 return true

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed:
   if event.position.y > 1100:
    pad_touch = event.index
    update_pad(event.position)
   else: request_move(event.position)
  elif event.index == pad_touch:
   pad_touch = -1
   pad_dir = Vector2.ZERO
 if event is InputEventScreenDrag and event.index == pad_touch: update_pad(event.position)
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed:
   if event.position.y > 1100:
    pad_touch = -2
    update_pad(event.position)
   else: request_move(event.position)
  elif pad_touch == -2:
   pad_touch = -1
   pad_dir = Vector2.ZERO
 if event is InputEventMouseMotion and pad_touch == -2: update_pad(event.position)

func update_pad(p: Vector2) -> void:
 var diff := p-Vector2(129,1184)
 pad_dir = diff.normalized() if diff.length() > 15 and diff.length() < 160 else Vector2.ZERO
 path.clear()
 has_target = false

func _physics_process(delta: float) -> void:
 var dir := pad_dir
 var keys := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
 if not keys.is_zero_approx():
  dir = keys.normalized()
  path.clear()
  has_target = false
 if dir.is_zero_approx() and not path.is_empty():
  while not path.is_empty() and player.position.distance_to(path[0]) < 6: path.remove_at(0)
  if not path.is_empty(): dir = player.position.direction_to(path[0])
  else: has_target = false
 player.velocity = dir*SPEED
 player.move_and_slide()
 moving = player.velocity.length() > 2
 if moving:
  step_clock += delta*9
  facing = dir
 nearby = "Apna mohalla"
 if player.position.distance_to(npcs[0].pos) < 100: nearby = "Chai tapri ke paas"
 if player.position.distance_to(npcs[1].pos) < 100: nearby = "Kirana store ke paas"
 queue_redraw()

func box(r: Rect2,c: Color,border: Color=Color.TRANSPARENT,width: float=2) -> void:
 draw_rect(r,c)
 if border.a > 0: draw_rect(r,border,false,width)
func label(text: String,p: Vector2,size: int,c: Color=INK) -> void:
 draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func center(text: String,p: Vector2,size: int,c: Color=INK) -> void:
 label(text,p-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),size,c)
func line(a: Vector2,b: Vector2,c: Color,w: float=2) -> void:
 draw_line(a,b,c,w)

func _draw() -> void:
 # Warm ground and a continuous road make this a neighbourhood, not a tile sample.
 box(Rect2(0,0,720,1280),SAND)
 box(Rect2(24,154,672,920),Color("d9c8a0"))
 for x in range(34,697,27):
  for y in range(172,1070,29):
   if (x+y)%3 == 0: draw_circle(Vector2(x,y),1.5,Color("c6b58e"))
 box(Rect2(282,154,156,920),Color("a6aa97"))
 box(Rect2(292,154,136,920),ROAD)
 box(Rect2(24,639,672,138),Color("a6aa97"))
 box(Rect2(24,651,672,114),ROAD)
 # lane paint, curb and drain tiles
 for y in range(166,1070,28):
  box(Rect2(278,y,9,18),Color("efe5c9") if y%56 < 28 else Color("8f9690"))
  box(Rect2(433,y,9,18),Color("efe5c9") if y%56 < 28 else Color("8f9690"))
 for y in range(182,1050,62):
  if y < 621 or y > 775: box(Rect2(357,y,6,29),Color("d8ceb0"))
 for x in range(38,690,65):
  if x < 270 or x > 445: box(Rect2(x,706,30,4),Color("d8ceb0"))
 for y in range(616,640,9): box(Rect2(300,y,120,5),Color("ece2bf"))
 for y in range(779,805,9): box(Rect2(300,y,120,5),Color("ece2bf"))
 # paving in front of shops, linked to the road
 for r in [Rect2(44,373,234,77),Rect2(444,395,234,52)]:
  box(r,Color("c6b68f"))
  for x in range(int(r.position.x),int(r.end.x),24): line(Vector2(x,r.position.y),Vector2(x,r.end.y),Color("b3a581"),1)
  for y in range(int(r.position.y),int(r.end.y),24): line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color("b3a581"),1)
 for b in buildings: draw_building(b)
 # Chai seating and kettles: owned art, no assets or licenses to chase.
 for p in [Vector2(83,410),Vector2(145,410)]:
  draw_circle(p+Vector2(4,7),19,Color("a49272"))
  draw_circle(p,17,Color("885a3e"))
  draw_circle(p,12,Color("b8844f"))
  draw_circle(p+Vector2(-4,-3),4,CREAM)
  draw_circle(p+Vector2(5,4),3,Color("603f2b"))
  box(Rect2(p.x-24,p.y-6,9,17),Color("41645f"))
  box(Rect2(p.x+17,p.y-6,9,17),Color("41645f"))
 # cart at the crossing, fruit in baskets
 box(Rect2(469,669,100,55),Color(0,0,0,.17))
 box(Rect2(462,661,100,55),Color("855733"),INK)
 box(Rect2(466,666,92,38),Color("e4b65e"))
 for x in [484,516,545]:
  for y in [676,689]: draw_circle(Vector2(x,y),7,Color("c98146") if x == 484 else Color("80974a"))
 for x in [467,555]: draw_circle(Vector2(x,714),7,INK)
 box(Rect2(457,641,110,23),Color("db9744"),INK)
 center("SABZI THELA",Vector2(512,657),12,CREAM)
 # roadside greenery, trunks are blocked in physics
 tree(Vector2(112,718),38)
 tree(Vector2(601,727),39)
 tree(Vector2(153,1030),29)
 tree(Vector2(585,1034),31)
 for p in [Vector2(70,195),Vector2(651,190),Vector2(52,796),Vector2(662,808)]:
  box(Rect2(p-Vector2(11,5),Vector2(22,15)),Color("ac7250"))
  draw_circle(p-Vector2(0,8),14,Color("708758"))
 # parked scooter, bicycle, hand pump, electric poles
 scooter(Vector2(270,532),Color("3a7479"))
 scooter(Vector2(453,921),Color("a85243"))
 for p in [Vector2(34,476),Vector2(685,499)]:
  draw_circle(p+Vector2(4,4),9,Color(0,0,0,.12))
  box(Rect2(p-Vector2(3,5),Vector2(6,70)),Color("6b5b49"))
  line(p-Vector2(13,0),p+Vector2(13,0),INK,4)
 line(Vector2(34,476),Vector2(60,179),Color("7e725b"),1)
 line(Vector2(685,499),Vector2(652,178),Color("7e725b"),1)
 box(Rect2(62,994,55,12),Color("aa9573"))
 box(Rect2(80,970,12,31),Color("4b8077"))
 line(Vector2(86,976),Vector2(102,965),INK,4)
 label("Nalka",Vector2(65,1024),14,Color("796e52"))
 # quiet map annotations
 center("BAZAAR ROAD",Vector2(360,191),14,CREAM)
 center("PEEPAL CHOWK",Vector2(183,761),12,Color("f0e7ca"))
 if has_target:
  for i in range(0,path.size(),3): draw_circle(path[i],2,Color(0.89,0.81,0.46,.5))
  draw_arc(target,14,0,TAU,32,Color("fbe9a1"),2)
  draw_circle(target,4,Color("fbe9a1"))
 for npc in npcs:
  person(npc.pos,npc.shirt,false)
  center(npc.name,npc.pos+Vector2(0,37),14,INK)
 person(player.position,Color("327f93"),true)
 draw_hud()

func draw_building(b: Dictionary) -> void:
 var r: Rect2 = b.rect
 box(Rect2(r.position+Vector2(8,13),r.size+Vector2(2,4)),Color(0.18,0.2,0.16,.22))
 box(r,b.color,Color("695541"),3)
 # raised roof rim and tile rows
 box(Rect2(r.position+Vector2(7,7),Vector2(r.size.x-14,r.size.y-53)),b.color.lightened(.1),Color("e0b080"),2)
 for y in range(int(r.position.y)+17,int(r.end.y)-53,12):
  line(Vector2(r.position.x+9,y),Vector2(r.end.x-9,y),b.color.darkened(.17),2)
 for x in range(int(r.position.x)+20,int(r.end.x)-10,25):
  line(Vector2(x,r.position.y+9),Vector2(x,r.end.y-53),b.color.darkened(.11),1)
 # roof detail, front wall, sign and doorway
 box(Rect2(r.position.x+13,r.position.y+13,29,18),b.color.darkened(.18))
 box(Rect2(r.position.x+18,r.position.y+16,18,7),b.color.lightened(.2))
 var sy := r.end.y-50
 box(Rect2(r.position.x+8,sy,r.size.x-16,34),Color("f3dfb4"),Color("826646"),2)
 center(b.name,Vector2(r.get_center().x,sy+22),16,INK)
 box(Rect2(r.get_center().x-18,r.end.y-17,36,17),Color("453e31"))
 box(Rect2(r.get_center().x-21,r.end.y,42,7),Color("bcad8d"))
 if b.kind in ["chai","store"]:
  # scalloped striped awning and a shop counter
  var a := Rect2(r.position.x-3,r.end.y-4,r.size.x+6,18)
  box(a,Color("fff0ca"),Color("826646"))
  for x in range(int(a.position.x),int(a.end.x)-5,24):
   box(Rect2(x,a.position.y,12,18),Color("b5523e") if b.kind == "chai" else Color("46887c"))
  box(Rect2(r.position.x+12,r.end.y+15,r.size.x-24,11),Color("9f7645"))
  if b.kind == "chai":
   draw_circle(Vector2(r.position.x+35,r.end.y+15),8,Color("b6b9a6"))
   draw_circle(Vector2(r.position.x+35,r.end.y+13),4,Color("54625b"))
   for x in range(int(r.end.x)-65,int(r.end.x)-20,12): box(Rect2(x,r.end.y+9,6,9),CREAM)
  else:
   for x in range(int(r.position.x)+20,int(r.end.x)-10,19):
    box(Rect2(x,r.end.y+8,11,13),Color("d59551") if x%2 == 0 else Color("b56e53"))
  center(b.sub,Vector2(r.get_center().x,r.position.y-12),16,Color("766341"))
 else:
  for x in [r.position.x+15,r.end.x-42]:
   box(Rect2(x,r.end.y-16,27,14),Color("335c5a"),Color("edcda0"))
   line(Vector2(x+13,r.end.y-16),Vector2(x+13,r.end.y-2),Color("e4bf90"),2)
  box(Rect2(r.end.x-47,r.position.y+16,27,29),Color("c8c4ad"),INK)
  draw_circle(Vector2(r.end.x-33,r.position.y+29),8,Color("5c716c"))

func tree(p: Vector2,radius: float) -> void:
 draw_circle(p+Vector2(12,12),radius,Color(0.21,0.28,0.14,.18))
 box(Rect2(p-Vector2(6,0),Vector2(12,17)),Color("816044"))
 draw_circle(p-Vector2(9,3),radius*.76,Color("496f53"))
 draw_circle(p+Vector2(14,-4),radius*.7,Color("5c8058"))
 draw_circle(p-Vector2(1,15),radius*.66,Color("749058"))
 draw_circle(p-Vector2(13,19),radius*.3,Color("859e60"))

func scooter(p: Vector2,c: Color) -> void:
 box(Rect2(p-Vector2(9,26)+Vector2(4,5),Vector2(18,53)),Color(0,0,0,.18))
 box(Rect2(p-Vector2(4,30),Vector2(8,60)),INK)
 box(Rect2(p-Vector2(10,22),Vector2(20,46)),c,INK)
 box(Rect2(p-Vector2(7,1),Vector2(14,18)),Color("3c4039"))
 line(p-Vector2(17,13),p+Vector2(17,-13),INK,3)
 box(Rect2(p-Vector2(5,23),Vector2(10,5)),CREAM)

func person(p: Vector2,shirt: Color,is_player: bool) -> void:
 draw_set_transform(p)
 draw_style_box(shadow_style(),Rect2(-14,7,28,13))
 var stride := sin(step_clock)*3 if is_player and moving else 0.0
 box(Rect2(-9,5+stride,7,13),Color("303c43"))
 box(Rect2(3,5-stride,7,13),Color("303c43"))
 box(Rect2(-10,15+stride,8,4),Color("26312f"))
 box(Rect2(3,15-stride,8,4),Color("26312f"))
 box(Rect2(-14,-11,7,19),Color("ba875d"))
 box(Rect2(8,-11,7,19),Color("ba875d"))
 box(Rect2(-9,-13,19,22),shirt,shirt.darkened(.26),2)
 line(Vector2(-7,-10),Vector2(7,-10),shirt.lightened(.22),2)
 draw_circle(Vector2(0,-19),10,Color("cb9568"))
 draw_arc(Vector2(0,-21),9,PI,TAU,12,Color("3b3630"),7)
 if is_player:
  draw_arc(Vector2(0,9),23,0,TAU,32,Color("f9e6a3"),2)
  draw_colored_polygon(PackedVector2Array([Vector2(-5,-42),Vector2(5,-42),Vector2(0,-34)]),Color("fff1b5"))
 draw_set_transform(Vector2.ZERO)

func shadow_style() -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = Color(0,0,0,.21)
 s.corner_radius_top_left=8
 s.corner_radius_top_right=8
 s.corner_radius_bottom_left=8
 s.corner_radius_bottom_right=8
 return s

func draw_hud() -> void:
 box(Rect2(0,0,720,140),INK)
 label("CHOWK",Vector2(30,60),42,CREAM)
 label("APNA MOHALLA",Vector2(32,91),17,Color("a7beb0"))
 box(Rect2(558,31,132,33),Color("45635a"))
 center("EXPLORE / V1",Vector2(624,54),14,CREAM)
 label("Subah  /  Bazaar Road",Vector2(33,122),16,Color("d3d5b8"))
 # bottom controls stay outside the playable area
 box(Rect2(0,1096,720,184),INK)
 line(Vector2(0,1096),Vector2(720,1096),Color("f1dba5"),3)
 draw_circle(Vector2(129,1184),66,Color("38534c"))
 draw_circle(Vector2(129,1184),59,Color("4c665c"))
 draw_circle(Vector2(129,1184),23,Color("293f3a"))
 for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
  var p: Vector2 = Vector2(129,1184)+d*43
  var side: Vector2 = Vector2(-d.y,d.x)
  draw_colored_polygon(PackedVector2Array([p+d*7,p-d*5+side*8,p-d*5-side*8]),Color("efe2bc"))
 label("Yahan tap karo, wahan chalo",Vector2(233,1154),23,CREAM)
 label("Ya left wala pad dabao",Vector2(234,1188),18,Color("afc6b7"))
 label(nearby,Vector2(234,1227),18,Color("e5c16d"))
 label("Abhi sirf ghoomo. Baat-cheet agle step mein.",Vector2(233,1256),14,Color("93aa9e"))
