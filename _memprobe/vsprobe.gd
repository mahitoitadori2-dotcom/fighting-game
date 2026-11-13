extends Node
## TEMPORARY (delete after use): every Story enemy / boss in a Versus fight vs the CPU Warrior.

func _ready() -> void:
	_run.call(get_tree())


static func _run(tree: SceneTree) -> void:
	await tree.process_frame
	ArenaManager.p1_cpu = true
	CharacterRoster.selected_id = "warrior"
	var ids: Array = []
	for e in EnemyManager.entries():
		if e.get("story", false):
			ids.append(String(e["id"]))
	print("VS testing %d story enemies/bosses" % ids.size())
	for id in ids:
		CharacterRoster.opponent_id = id
		print("VS BEGIN ", id)
		tree.change_scene_to_file("res://Main.tscn")
		await tree.create_timer(1.0).timeout
		Engine.time_scale = 3.0
		var opp: Fighter = null
		var me: Fighter = null
		for n in tree.get_nodes_in_group("fighters"):
			var f := n as Fighter
			if f != null and f.slot == 2:
				opp = f
			elif f != null and f.slot == 1:
				me = f
		if opp == null:
			print("VS RESULT %s: NO OPPONENT SPAWNED" % id)
			Engine.time_scale = 1.0
			continue
		var opp_hp0 := opp.hp
		var opp_max := opp.data.max_hp
		await tree.create_timer(30.0).timeout                 # 30 s at 3x = ~10 s real
		Engine.time_scale = 1.0
		var lost_me := 100
		if is_instance_valid(me):
			lost_me = me.data.max_hp - me.hp
		var alive := is_instance_valid(opp) and not opp.is_dead
		var y := opp.global_position.y if is_instance_valid(opp) else 0.0
		print("VS RESULT %s: hp %d/%d -> %d, warrior lost %d HP, alive=%s, y=%.0f, scene=%s" % [id, opp_hp0, opp_max,
			opp.hp if is_instance_valid(opp) else -1, lost_me, alive, y, tree.current_scene.name])
		print("VS END ", id)
	tree.quit()
