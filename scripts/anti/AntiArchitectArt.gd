class_name AntiArchitectArt
extends RefCounted
## The ANTI ARCHITECT: the very same model and animations as The Mighty Architect
## (ArchitectArt), drawn with the REVERSE / negative palette (ArchitectArt.ANTI_PALETTE):
## black helmet + chest plate, ORANGE limbs, pale grey details, a glowing orange core.
## Plus an orange charge glow while Overcharge builds up.


static func draw(c: CanvasItem, p: Player) -> void:
	var charge := 0.0
	if p is AntiArchitect:
		charge = (p as AntiArchitect).charge_amt
	if charge > 0.0:
		c.draw_circle(Vector2(0, -70), 50.0 + 40.0 * charge, Color(1.0, 0.45, 0.05, 0.15 + 0.35 * charge))
	ArchitectArt.set_palette(ArchitectArt.ANTI_PALETTE)
	ArchitectArt.draw(c, p)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)


static func draw_portrait(c: CanvasItem, t: float) -> void:
	ArchitectArt.set_palette(ArchitectArt.ANTI_PALETTE)
	ArchitectArt.draw_portrait(c, t)
	ArchitectArt.set_palette(ArchitectArt.NORMAL_PALETTE)
