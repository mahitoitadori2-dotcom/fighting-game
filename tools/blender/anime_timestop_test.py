"""ANIME / MANGA STYLE TEST (The Last Stretch, the moment the Architect STOPS TIME). ~5 s.

Run headless (no window):
  blender -b --factory-startup --python tools/blender/anime_timestop_test.py -- <hero_glb_dir> <out_dir>

Look: 3D models dressed as 2D anime - flat toon colour with hard shadow steps, thick ink outlines,
animated ON TWOS (12 drawings a second). When time stops, the WORLD turns into a black-and-white
MANGA page (screentone dots, ink) - only the Architect stays in colour, his core blazing blue.
Shots: A) through the bars, rain, head down  B) close-up: the core lights, the head comes up
       C) IMPACT FRAME (inverted)  D) wide: manga world, rain frozen as ink, speed lines, he stands.
Writes PNG frames + anime_test.mp4 (to watch) + anime_test.ogv (Godot's video format) into <out_dir>.
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

FPS = 12                                  # On twos: 12 drawings a second
LENGTH = 5.0
W, H = 1280, 720


# ============================================================
# TOON / MANGA MATERIALS
# ============================================================
def _sock(sockets, ident):
    for s in sockets:
        if s.identifier == ident or s.name == ident:
            return s
    return sockets[0]


def toon_mat(name, col, manga=True, glow=0.0):
    """Flat toon colour (3 hard steps). Value nodes MANGA / IMPACT / GLOW are set every frame."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    N = nt.nodes.new
    L = nt.links.new
    out = N("ShaderNodeOutputMaterial")
    dif = N("ShaderNodeBsdfDiffuse")
    s2r = N("ShaderNodeShaderToRGB")
    L(dif.outputs[0], s2r.inputs[0])
    bw = N("ShaderNodeRGBToBW")
    L(s2r.outputs[0], bw.inputs[0])
    ramp = N("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.42, 0.42, 0.5, 1)          # Shadow (a little blue)
    e = ramp.color_ramp.elements[1]
    e.position = 0.12
    e.color = (0.72, 0.72, 0.76, 1)
    e2 = ramp.color_ramp.elements.new(0.42)
    e2.color = (1, 1, 1, 1)
    L(bw.outputs[0], ramp.inputs[0])
    base = N("ShaderNodeRGB")
    base.outputs[0].default_value = (*col, 1)
    toon = N("ShaderNodeVectorMath")
    toon.operation = "MULTIPLY"
    L(base.outputs[0], toon.inputs[0])
    L(ramp.outputs[0], toon.inputs[1])
    gray0 = N("ShaderNodeRGBToBW")
    L(toon.outputs[0], gray0.inputs[0])
    gray = N("ShaderNodeMath")                                        # Brighter for the manga page (night is dark)
    gray.operation = "MULTIPLY"
    gray.use_clamp = True
    L(gray0.outputs[0], gray.inputs[0])
    gray.inputs[1].default_value = 1.7
    # --- Screentone: dots in screen space, bigger where it is darker ---
    tc = N("ShaderNodeTexCoord")
    sep = N("ShaderNodeSeparateXYZ")
    L(tc.outputs["Window"], sep.inputs[0])

    def math(op, a, b=None, val=None):
        n = N("ShaderNodeMath")
        n.operation = op
        if isinstance(a, float):
            n.inputs[0].default_value = a
        else:
            L(a, n.inputs[0])
        if b is not None:
            if isinstance(b, float):
                n.inputs[1].default_value = b
            else:
                L(b, n.inputs[1])
        return n.outputs[0]

    dots = 90.0
    fx = math("FRACT", math("MULTIPLY", sep.outputs[0], dots * W / H))
    fy = math("FRACT", math("MULTIPLY", sep.outputs[1], dots))
    comb = N("ShaderNodeCombineXYZ")
    L(math("SUBTRACT", fx, 0.5), comb.inputs[0])
    L(math("SUBTRACT", fy, 0.5), comb.inputs[1])
    ln = N("ShaderNodeVectorMath")
    ln.operation = "LENGTH"
    L(comb.outputs[0], ln.inputs[0])
    r = math("MULTIPLY", math("SUBTRACT", 1.0, gray.outputs[0]), 0.78)
    ink = math("LESS_THAN", _sock(ln.outputs, "Value"), r)
    paper = math("SUBTRACT", 1.0, ink)
    light = math("GREATER_THAN", gray.outputs[0], 0.86)
    dark = math("LESS_THAN", gray.outputs[0], 0.10)
    mg = math("MULTIPLY", math("MAXIMUM", paper, light), math("SUBTRACT", 1.0, dark))
    mcol = N("ShaderNodeVectorMath")
    mcol.operation = "SCALE"
    mcol.inputs[0].default_value = (0.96, 0.95, 0.9)
    L(mg, _sock(mcol.inputs, "Scale"))
    # MANGA amount (0 colour .. 1 manga), only for the world
    mv = N("ShaderNodeValue")
    mv.name = "MANGA"
    mv.outputs[0].default_value = 0.0
    amt = math("MULTIPLY", mv.outputs[0], 1.0 if manga else 0.0)
    mix1 = N("ShaderNodeMix")
    mix1.data_type = "VECTOR"
    L(amt, _sock(mix1.inputs, "Factor_Float"))
    L(toon.outputs[0], _sock(mix1.inputs, "A_Vector"))
    L(mcol.outputs[0], _sock(mix1.inputs, "B_Vector"))
    # IMPACT frame: hard inverted black / white
    iv = N("ShaderNodeValue")
    iv.name = "IMPACT"
    inv = math("LESS_THAN", gray.outputs[0], 0.38)
    icol = N("ShaderNodeCombineXYZ")
    for i in range(3):
        L(inv, icol.inputs[i])
    mix2 = N("ShaderNodeMix")
    mix2.data_type = "VECTOR"
    L(iv.outputs[0], _sock(mix2.inputs, "Factor_Float"))
    L(_sock(mix1.outputs, "Result_Vector"), _sock(mix2.inputs, "A_Vector"))
    L(icol.outputs[0], _sock(mix2.inputs, "B_Vector"))
    em = N("ShaderNodeEmission")
    L(_sock(mix2.outputs, "Result_Vector"), em.inputs["Color"])
    # GLOW (the core): extra light on top
    gv = N("ShaderNodeValue")
    gv.name = "GLOW"
    gv.outputs[0].default_value = glow
    em2 = N("ShaderNodeEmission")
    em2.inputs["Color"].default_value = (*col, 1)
    L(gv.outputs[0], em2.inputs["Strength"])
    add = N("ShaderNodeAddShader")
    L(em.outputs[0], add.inputs[0])
    L(em2.outputs[0], add.inputs[1])
    L(add.outputs[0], out.inputs["Surface"])
    return m


def outline_mat():
    m = bpy.data.materials.new("ink")
    m.use_nodes = True
    m.use_backface_culling = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    iv = nt.nodes.new("ShaderNodeValue")
    iv.name = "IMPACT"
    nt.links.new(iv.outputs[0], em.inputs["Color"])
    nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m


INK = None


def ink(ob, thick):
    ob.data.materials.append(INK)
    mod = ob.modifiers.new("ink", "SOLIDIFY")
    mod.thickness = thick
    mod.offset = 1.0
    mod.use_flip_normals = True
    mod.material_offset = len(ob.data.materials) - 1


def set_all(name, v):
    for m in bpy.data.materials:
        if m.node_tree and name in m.node_tree.nodes:
            m.node_tree.nodes[name].outputs[0].default_value = v


# ============================================================
# SET
# ============================================================
def box(name, size, loc, mat, thick=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(mat)
    if thick > 0:
        ink(ob, thick)
    return ob


def cyl(name, r, h, loc, mat, thick=0.012, verts=10):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=verts)
    ob = bpy.context.object
    ob.name = name
    ob.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    if thick > 0:
        ink(ob, thick)
    return ob


ARCH_COL = {"leg": (0.22, 0.86, 0.28), "arm": (0.22, 0.86, 0.28), "chest": (1.0, 1.0, 1.0), "belt": (0.25, 0.27, 0.31),
            "foot": (0.12, 0.13, 0.16), "hand": (0.08, 0.52, 0.15), "head_col": (1.0, 1.0, 1.0), "visor": (0.07, 0.08, 0.11),
            "core": (0.18, 0.68, 1.0)}


def architect(glb):
    """Imports the Architect's Blender model and builds a little rig of empties (the Hero3D joints)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=glb)
    parts = {o.name.split(".")[0]: o for o in set(bpy.data.objects) - before if o.type == "MESH"}
    import bmesh
    for o in parts.values():
        bm = bmesh.new()                                              # Outward normals (the ink shell needs them)
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(o.data)
        bm.free()
        o.parent = None
        o.location = (0, 0, 0)
        o.rotation_euler = (0, 0, 0)
        for i, slot in enumerate(o.data.materials):
            key = slot.name.split(".")[0] if slot else "chest"
            o.data.materials[i] = toon_mat("A_" + key, ARCH_COL.get(key, (0.8, 0.8, 0.8)), manga=False, glow=0.0)
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth()
        ink(o, 0.018)
    rig = {}

    def empty(name, parent, loc):
        e = bpy.data.objects.new("rig_" + name, None)
        bpy.context.scene.collection.objects.link(e)
        e.parent = parent
        e.location = loc
        rig[name] = e
        return e

    def attach(part, parent):
        ob = parts[part].copy()
        ob.data = parts[part].data
        bpy.context.scene.collection.objects.link(ob)
        ob.parent = parent
        return ob

    root = empty("root", None, (0, 0, 0))
    hips = empty("hips", root, (0, 0, 0.95))
    attach("chest", hips)
    head = empty("head", hips, (0.02, 0, 1.08))
    attach("head", head)
    for side, tag in ((1.0, "n"), (-1.0, "f")):
        hip = empty("hip_" + tag, hips, (0, -side * 0.16, 0))
        attach("thigh", hip)
        knee = empty("knee_" + tag, hip, (0, 0, -0.475))
        attach("shin", knee)
        sh = empty("sh_" + tag, hips, (0, -side * 0.48, 0.8))
        attach("upperarm", sh)
        el = empty("el_" + tag, sh, (0, 0, -0.425))
        attach("forearm", el)
    for o in parts.values():                                         # The originals were only templates
        bpy.data.objects.remove(o)
    return rig


def pose(rig, stand, head_up, lean):
    """stand 0 = kneeling upright (shins flat behind), 1 = standing. Godot-style angles -> Blender Y."""
    knee = 1.57 * (1.0 - stand)
    rig["hips"].location.z = 0.58 + 0.37 * stand
    rig["hips"].rotation_euler.y = lean
    for tag, off in (("n", 0.0), ("f", 0.08)):
        rig["hip_" + tag].rotation_euler.y = -0.05 * (1.0 - stand) - off * stand
        rig["knee_" + tag].rotation_euler.y = knee
        rig["sh_" + tag].rotation_euler = (0.12 if tag == "n" else -0.12, -0.25 * (1.0 - stand) - 0.08, 0)
        rig["el_" + tag].rotation_euler.y = -0.5 * (1.0 - stand) - 0.15
    rig["head"].rotation_euler.y = 0.55 * (1.0 - head_up) - 0.05 * head_up


# ============================================================
# MAIN
# ============================================================
def main():
    global INK
    argv = sys.argv[sys.argv.index("--") + 1:]
    glb_dir = os.path.abspath(argv[0])
    out_dir = os.path.abspath(argv[1])
    os.makedirs(out_dir, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = W
    sc.render.resolution_y = H
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.0, 1)
    INK = outline_mat()
    stone = toon_mat("stone", (0.30, 0.32, 0.42))
    stone_d = toon_mat("stone_d", (0.20, 0.21, 0.30))
    iron = toon_mat("iron", (0.40, 0.42, 0.50))
    lamp = toon_mat("lamp", (1.0, 0.62, 0.25), glow=1.5)
    rainm = toon_mat("rain", (0.55, 0.65, 0.95))
    # The cell: floor, back wall with a barred window, side walls, the front bars, a lantern outside
    box("floor", (12, 8, 0.2), (0, 0, -0.1), stone_d, 0.0)
    box("back", (0.3, 12, 4), (-1.75, 0, 2), stone, 0.04)
    for y in (-1.8, 1.8):
        box("side", (3.2, 0.3, 4), (0.0, y, 2), stone, 0.04)
    box("roof", (3.2, 3.9, 0.25), (0.0, 0, 3.4), stone_d, 0.04)
    win = box("window", (0.1, 0.9, 0.6), (-1.42, 0.5, 2.5), toon_mat("night", (0.45, 0.55, 0.85), glow=0.6), 0.0)
    for k in range(4):
        cyl("wbar", 0.025, 0.6, (-1.38, 0.2 + k * 0.2, 2.5), iron, 0.008)
    bars = []
    for k in range(9):
        bars.append(cyl("bar", 0.045, 3.4, (1.6, -1.6 + k * 0.4, 1.7), iron))
    box("beam", (0.15, 3.6, 0.18), (1.6, 0, 3.35), iron, 0.02)
    cyl("lamp_post", 0.04, 2.2, (2.6, 2.2, 1.1), iron)
    lantern = cyl("lantern", 0.14, 0.3, (2.6, 2.2, 2.3), lamp, 0.015, 8)
    # Rain outside the bars (it falls... then HANGS when time stops)
    rnd = random.Random(147)
    rain = []
    for i in range(90):
        x = rnd.uniform(1.8, 4.4)
        y = rnd.uniform(-2.6, 2.6)
        d = box("drop", (0.012, 0.012, 0.32), (x, y, 2.0), rainm, 0.0)
        rain.append((d, rnd.uniform(0, 4.0)))
    # The Architect
    rig = architect(os.path.join(glb_dir, "architect.glb"))
    rig["root"].rotation_euler.z = 0.0                                # Faces +X (towards the bars / camera)
    core_mats = [m for m in bpy.data.materials if m.name.startswith("A_core")]
    # Lights: cold moonlight from the window side, warm lantern from outside
    sun = bpy.data.objects.new("moon", bpy.data.lights.new("moon", "SUN"))
    sc.collection.objects.link(sun)
    sun.data.energy = 3.0
    sun.data.color = (0.75, 0.82, 1.0)
    sun.rotation_euler = (Vector((0, 0, 0)) - Vector((3.0, -2.0, 4.0))).to_track_quat("-Z", "Y").to_euler()
    pt = bpy.data.objects.new("lantern_l", bpy.data.lights.new("lantern_l", "POINT"))
    sc.collection.objects.link(pt)
    pt.location = (2.6, 2.2, 2.1)
    pt.data.energy = 120.0
    pt.data.color = (1.0, 0.65, 0.35)
    # Speed lines: thin ink wedges on a card in front of the camera
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    lines_mat = bpy.data.materials.new("speed")
    lines_mat.use_nodes = True
    lines_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0, 0, 0, 1)
    lines_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    speed = []
    for i in range(46):
        a = i / 46.0 * math.tau + rnd.uniform(-0.05, 0.05)
        r0 = rnd.uniform(0.34, 0.48)
        mesh = bpy.data.meshes.new("sl")
        w = rnd.uniform(0.004, 0.012)
        d = Vector((math.cos(a), math.sin(a), 0))
        n = Vector((-d.y, d.x, 0)) * w
        mesh.from_pydata([d * r0, d * 1.2 + n, d * 1.2 - n], [], [(0, 1, 2)])
        mesh.update()
        ob = bpy.data.objects.new("sl", mesh)
        ob.data.materials.append(lines_mat)
        sc.collection.objects.link(ob)
        ob.parent = cam
        ob.location = (0, 0, -0.5)
        ob.scale = (W / H * 0.45, 0.45, 1)
        speed.append(ob)

    def look(pos, target, lens):
        cam.location = pos
        cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens

    def k(t, a, b):
        return max(0.0, min(1.0, (t - a) / max(b - a, 1e-3)))

    def ease(x):
        return x * x * (3 - 2 * x)

    frames = int(LENGTH * FPS)
    for f in range(frames):
        t = f / FPS
        stopped = t >= 2.25                                           # TIME STOPS here
        impact = 2.25 <= t < 2.42
        manga = 1.0 if t >= 2.42 else 0.0
        set_all("MANGA", manga)
        set_all("IMPACT", 1.0 if impact else 0.0)
        sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.96, 0.95, 0.9, 1) if manga > 0 else (0.0, 0.0, 0.0, 1)
        # The core lights up, then BLAZES
        for m in core_mats:
            m.node_tree.nodes["GLOW"].outputs[0].default_value = 0.2 + 6.0 * ease(k(t, 0.9, 2.2)) + (3.0 if stopped else 0.0)
        # Rain: falls, then hangs in the air as ink strokes
        rt = min(t, 2.25)
        for d, off in rain:
            d.location.z = 3.6 - ((rt * 7.0 + off) % 3.6)
        # Him: head down -> head up (shot B) -> stands up slowly (shot D)
        pose(rig, ease(k(t, 2.9, 4.7)), ease(k(t, 1.1, 2.1)), 0.15 * (1.0 - k(t, 2.9, 4.7)))
        lantern.scale = (1, 1, 1.0 + (0.0 if stopped else 0.15 * math.sin(t * 20.0)))
        for i, bar in enumerate(bars):                                # Time stops: the bars burst off... and HANG
            br = random.Random(i * 31)
            fly = 1.0 if stopped else 0.0
            side = -1.0 if i < 4 else (1.0 if i > 4 else br.choice((-1.0, 1.0)))     # Burst out to the sides and UP
            bar.location = (1.6 + fly * br.uniform(0.2, 0.8), -1.6 + i * 0.4 + fly * side * br.uniform(0.6, 1.4), 1.7 + fly * br.uniform(0.8, 1.8))
            bar.rotation_euler = (fly * side * br.uniform(0.4, 1.1), fly * br.uniform(-0.5, 0.5), 0.0)
        for i, ob in enumerate(speed):
            ob.hide_render = not (t >= 2.42 and (f + i) % 3 != 0)
        if t < 1.0:                                                   # A: through the bars, rain
            look((3.9, -1.3, 1.45 + 0.05 * t), (0.0, 0.0, 1.15), 34 + 6 * t)
        elif t < 2.25:                                                # B: close on the core + visor
            u = k(t, 1.0, 2.25)
            look((2.0, -0.7, 1.4 + 0.1 * u), (0.2, 0.0, 1.32 + 0.12 * u), 44 + 12 * u)
        elif t < 2.42:                                                # C: impact frame (wide, inverted)
            look((4.2, -2.0, 1.0), (0.0, 0.0, 1.15), 34)
        else:                                                         # D: manga world, he rises
            u = ease(k(t, 2.42, LENGTH))
            look((4.6 - 0.6 * u, -2.6 + 0.9 * u, 0.6 + 0.4 * u), (0.0, 0.0, 1.25 + 0.4 * u), 30 + 6 * u)
        sc.frame_set(f + 1)
        if os.environ.get("ANIME_RAY") and f == frames - 1:                  # Debug: what is in front of him?
            dg = bpy.context.evaluated_depsgraph_get()
            cp = cam.matrix_world.translation
            for nm in ("sh_n", "hip_n", "head"):
                tgt = rig[nm].matrix_world.translation + Vector((0, 0, -0.2))
                hit, loc, nor, idx, ob, mt = sc.ray_cast(dg, cp, (tgt - cp).normalized())
                print("RAY", nm, "hit", ob.name if ob else None, round((loc - cp).length, 2), "target at", round((tgt - cp).length, 2))
            return
        sc.render.filepath = os.path.join(out_dir, "frame_%03d.png" % f)
        bpy.ops.render.render(write_still=True)
    print("ANIME frames:", frames)
    # Into videos: an image-sequence strip in a fresh scene, written as MP4 (to watch) and OGV (Godot)
    vs = bpy.data.scenes.new("video")
    vs.render.resolution_x = W
    vs.render.resolution_y = H
    vs.render.fps = FPS
    se = vs.sequence_editor_create()
    coll = se.strips if hasattr(se, "strips") else se.sequences       # (Blender 4.4+ renamed it, and an empty one is "false")
    strip = coll.new_image("frames", os.path.join(out_dir, "frame_000.png"), 1, 1)
    for f in range(1, frames):
        strip.elements.append("frame_%03d.png" % f)
    vs.frame_start = 1
    vs.frame_end = frames
    for fmt, codec, ext in (("MPEG4", "H264", "mp4"), ("OGG", "THEORA", "ogv")):
        if hasattr(vs.render.image_settings, "media_type"):          # Blender 5: video is its own media type
            vs.render.image_settings.media_type = "VIDEO"
        vs.render.image_settings.file_format = "FFMPEG"
        vs.render.ffmpeg.format = fmt
        vs.render.ffmpeg.codec = codec
        vs.render.ffmpeg.constant_rate_factor = "HIGH" if codec == "H264" else vs.render.ffmpeg.constant_rate_factor
        vs.render.filepath = os.path.join(out_dir, "anime_test." + ext)
        with bpy.context.temp_override(scene=vs):
            bpy.ops.render.render(animation=True, scene=vs.name)
        print("ANIME video:", vs.render.filepath)


main()
