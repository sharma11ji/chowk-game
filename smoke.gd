extends SceneTree
var town: Node2D
var failures := 0
func check(ok: bool,message: String) -> void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok: failures += 1
func wait_ticks(n: int) -> void:
 for i in range(n): await physics_frame
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 town = load("res://town.tscn").instantiate()
 root.add_child(town)
 await wait_ticks(3)
 check(town.npcs.size()==2,"Two stationary NPCs")
 check(town.buildings.size()==6,"Chai + kirana + four houses")
 var tap := InputEventScreenTouch.new()
 tap.index=0
 tap.pressed=true
 tap.position=Vector2(257,427)
 town._unhandled_input(tap)
 await wait_ticks(200)
 check(town.player.position.distance_to(Vector2(257,427))<18,"Touch tap walks to chai")
 check(town.request_move(Vector2(445,424)),"Path to kirana accepted")
 await wait_ticks(170)
 check(town.player.position.distance_to(Vector2(445,424))<18,"Walk across main road to kirana")
 check(not town.request_move(Vector2(550,300)),"Tap inside a roof is rejected")
 check(not town.request_move(Vector2(360,50)),"HUD cannot become a movement target")
 check(town.request_move(Vector2(124,804)),"Long route around walls accepted")
 await wait_ticks(310)
 check(town.player.position.distance_to(Vector2(124,804))<18,"Path routes around house and tree")
 # Actual contact against a house using CharacterBody2D physics.
 town.player.position=Vector2(360,535)
 town.path.clear()
 town.pad_dir=Vector2.LEFT
 await wait_ticks(65)
 check(town.player.position.x>258 and town.player.position.x<267,"Held movement cannot enter house wall")
 town.player.position=Vector2(360,790)
 tap.position=Vector2(129,1137)
 town._unhandled_input(tap)
 await wait_ticks(15)
 check(town.player.position.y<755,"Touch pad drives movement")
 tap.pressed=false
 town._unhandled_input(tap)
 var stop: Vector2 = town.player.position
 await wait_ticks(12)
 check(town.player.position.distance_to(stop)<4,"Releasing touch pad stops movement")
 town.player.position=Vector2(30,801)
 town.pad_dir=Vector2.LEFT
 await wait_ticks(30)
 check(town.player.position.x>=34,"World boundary prevents walking off map")
 print("RESULT: ",failures," failures")
 quit(failures)
