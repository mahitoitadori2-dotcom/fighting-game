"""Builds the 3D HERO models (Warrior, Architect, Enlightened One) for the 3D cutscenes / menus.

Run headless (no window):
  blender -b --factory-startup --python tools/blender/build_heroes.py -- <out_dir> [<preview_dir>]

One .glb per hero in <out_dir> (art/models/heroes). Every body PART is its own object with its
origin at the joint it turns around, matching the pivots of scripts/three_d/Hero3D.gd:
  chest   body pivot (hips, 0.95 above the feet)      head    head pivot (0.02, 1.08 above the hips)
  thigh   hip pivot          shin   knee pivot (0.475 below the hip, includes the boot)
  upperarm shoulder pivot    forearm elbow pivot (0.425 below the shoulder, includes the hand)
  sword   (warrior) the blade, pointing up from the grip; Hero3D places it in the hand
Materials are named after Hero3D palette slots (leg, arm, chest, belt, foot, hand, head_col, visor,
core) or fixed colours (dark, steel, grip, eye_gold): Godot swaps in its own outlined materials,
so the palettes, the Galaxy skin and the far-side shading keep working.

Axes: Blender X = forward (Godot +x), Z = up (Godot +y), -Y = the near side (Godot +z).
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

SEG = 14                       # Points around each lathe ring


# ============================================================
# MESH HELPERS (everything goes into one bmesh per part)
# ============================================================
class Part:
    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.mats = []

    def mat(self, m):
        if m not in self.mats:
            self.mats.append(m)
        return self.mats.index(m)

    def lathe(self, prof, m, off=(0, 0, 0), seg=SEG, yaw=0.0):
        """prof: rows of (z, rx, ry[, cx]) = height, half-depth (X), half-width (Y), forward shift.
        A row with radius 0 closes the end in a point."""
        mi = self.mat(m)
        bm = self.bm
        rows = []
        for row in prof:
            z, rx, ry = row[0], row[1], row[2]
            cx = row[3] if len(row) > 3 else 0.0
            if rx <= 1e-5 and ry <= 1e-5:
                rows.append([bm.verts.new((off[0] + cx, off[1], off[2] + z))])
                continue
            ring = []
            for i in range(seg):
                a = math.tau * i / seg + yaw
                ring.append(bm.verts.new((off[0] + cx + math.cos(a) * rx, off[1] + math.sin(a) * ry, off[2] + z)))
            rows.append(ring)
        for r0, r1 in zip(rows, rows[1:]):
            if len(r0) == 1 and len(r1) == 1:
                continue
            for i in range(seg):
                j = (i + 1) % seg
                if len(r0) == 1:
                    f = bm.faces.new((r0[0], r1[j], r1[i]))
                elif len(r1) == 1:
                    f = bm.faces.new((r0[i], r0[j], r1[0]))
                else:
                    f = bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
                f.material_index = mi
                f.smooth = True

    def shell(self, prof, m, a0, a1, thick=0.025, steps=10, off=(0, 0, 0)):
        """A curved armour plate: part of a lathe surface (angles a0..a1 in degrees, 0 = forward),
        with a real thickness so the black outline wraps it."""
        mi = self.mat(m)
        bm = self.bm
        outer, inner = [], []
        for row in prof:
            z, rx, ry = row[0], row[1], row[2]
            cx = row[3] if len(row) > 3 else 0.0
            ro, ri = [], []
            for i in range(steps + 1):
                a = math.radians(a0 + (a1 - a0) * i / steps)
                ro.append(bm.verts.new((off[0] + cx + math.cos(a) * rx, off[1] + math.sin(a) * ry, off[2] + z)))
                ri.append(bm.verts.new((off[0] + cx + math.cos(a) * (rx - thick), off[1] + math.sin(a) * (ry - thick), off[2] + z)))
            outer.append(ro)
            inner.append(ri)
        faces = []
        nr = len(prof)
        for r in range(nr - 1):
            for i in range(steps):
                faces.append(bm.faces.new((outer[r][i], outer[r][i + 1], outer[r + 1][i + 1], outer[r + 1][i])))
                faces.append(bm.faces.new((inner[r][i], inner[r + 1][i], inner[r + 1][i + 1], inner[r][i + 1])))
            for i in (0, steps):                                   # Left / right edges
                faces.append(bm.faces.new((outer[r][i], outer[r + 1][i], inner[r + 1][i], inner[r][i])))
        for r in (0, nr - 1):                                      # Top / bottom edges
            for i in range(steps):
                faces.append(bm.faces.new((outer[r][i], inner[r][i], inner[r][i + 1], outer[r][i + 1])))
        for f in faces:
            f.material_index = mi
            f.smooth = True

    def ellipsoid(self, c, r, m, seg=SEG, rings=8, flat_bottom=None):
        prof = []
        for k in range(rings + 1):
            t = math.pi * k / rings                       # 0 = bottom pole
            z = -math.cos(t) * r[2]
            s = math.sin(t)
            if flat_bottom is not None and z < flat_bottom:
                z = flat_bottom
            prof.append((z, s * r[0], s * r[1]))
        self.lathe(prof, m, c, seg)

    def box(self, c, size, m, rot=None):
        mi = self.mat(m)
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        vs = res["verts"]
        mat = Matrix.Translation(Vector(c)) @ (rot if rot is not None else Matrix.Identity(4)) @ Matrix.Diagonal((*size, 1.0))
        bmesh.ops.transform(self.bm, matrix=mat, verts=vs)
        for f in {f for v in vs for f in v.link_faces}:
            f.material_index = mi
            f.smooth = True

    def slab(self, outline, depth, m, y0=0.0):
        """A flat shape: outline points (x, z) extruded along Y (centred on y0)."""
        mi = self.mat(m)
        bm = self.bm
        front = [bm.verts.new((x, y0 - depth / 2, z)) for x, z in outline]
        back = [bm.verts.new((x, y0 + depth / 2, z)) for x, z in outline]
        n = len(outline)
        faces = [bm.faces.new(front), bm.faces.new(list(reversed(back)))]
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((front[j], front[i], back[i], back[j])))
        for f in faces:
            f.material_index = mi
            f.smooth = True
        bmesh.ops.recalc_face_normals(bm, faces=faces)

    def build(self, coll):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(material(m))
        ob = bpy.data.objects.new(self.name, me)
        coll.objects.link(ob)
        return ob


PREVIEW_COL = {
    "leg": (0.16, 0.12, 0.26), "arm": (0.16, 0.12, 0.26), "chest": (0.16, 0.12, 0.26), "belt": (0.32, 0.25, 0.48),
    "foot": (0.09, 0.07, 0.15), "hand": (0.09, 0.07, 0.15), "head_col": (0.78, 0.80, 0.86), "visor": (0.07, 0.08, 0.11),
    "core": (0.3, 0.9, 1.0), "dark": (0.04, 0.02, 0.06), "steel": (0.75, 0.77, 0.82), "grip": (0.25, 0.15, 0.08),
    "eye_gold": (1.0, 0.85, 0.35),
}
_preview_override = {}


def material(name):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        c = _preview_override.get(name, PREVIEW_COL.get(name, (0.8, 0.8, 0.8)))
        m.diffuse_color = (*c, 1.0)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (*c, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.8
    return m


# ============================================================
# BODY PARTS (shared, tuned per hero by `k`)
# ============================================================
def thigh(k):
    p = Part("thigh")
    t = k.get("limb", 1.0)
    p.lathe([(0.06, 0, 0), (0.04, 0.10 * t, 0.10 * t), (0.0, 0.145 * t, 0.14 * t, 0.01), (-0.14, 0.15 * t, 0.14 * t, 0.015),
             (-0.32, 0.12 * t, 0.115 * t, 0.01), (-0.46, 0.105 * t, 0.10 * t), (-0.52, 0, 0)], "leg")
    if k.get("knee_pad"):
        p.shell([(-0.38, 0.125, 0.118, 0.01), (-0.47, 0.135, 0.125, 0.02), (-0.55, 0.118, 0.11, 0.01)], k["knee_pad"], -60, 60, 0.03)
    return p


def shin(k):
    p = Part("shin")
    t = k.get("limb", 1.0)
    p.lathe([(0.05, 0, 0), (0.03, 0.09 * t, 0.09 * t), (0.0, 0.11 * t, 0.105 * t), (-0.1, 0.12 * t, 0.11 * t, -0.015),
             (-0.24, 0.095 * t, 0.09 * t), (-0.3, 0.085 * t, 0.085 * t), (-0.33, 0, 0)], "leg")
    # Boot: a shaped shell from the shin down to a flat sole, toe pointing forward
    b = k.get("boot", 1.0)
    p.lathe([(-0.22, 0, 0, 0.0), (-0.24, 0.105 * b, 0.1 * b), (-0.32, 0.115 * b, 0.105 * b, 0.015),
             (-0.39, 0.15 * b, 0.11 * b, 0.05), (-0.44, 0.19 * b, 0.115 * b, 0.08), (-0.475, 0.19 * b, 0.11 * b, 0.08),
             (-0.48, 0, 0, 0.08)], "foot")
    if k.get("boot_cuff"):
        p.lathe([(-0.2, 0.0, 0.0), (-0.21, 0.11 * b, 0.105 * b), (-0.26, 0.12 * b, 0.115 * b), (-0.27, 0, 0)], k["boot_cuff"])
    return p


def upperarm(k):
    p = Part("upperarm")
    t = k.get("limb", 1.0)
    p.lathe([(0.05, 0, 0), (0.035, 0.08 * t, 0.08 * t), (0.0, 0.11 * t, 0.11 * t), (-0.12, 0.115 * t, 0.11 * t, 0.01),
             (-0.3, 0.09 * t, 0.088 * t), (-0.42, 0.08 * t, 0.08 * t), (-0.47, 0, 0)], "arm")
    return p


def forearm(k):
    p = Part("forearm")
    t = k.get("limb", 1.0)
    p.lathe([(0.04, 0, 0), (0.02, 0.075 * t, 0.075 * t), (-0.02, 0.09 * t, 0.088 * t), (-0.13, 0.1 * t, 0.095 * t, 0.01),
             (-0.3, 0.078 * t, 0.075 * t), (-0.36, 0.07 * t, 0.07 * t), (-0.39, 0, 0)], "arm")
    g = k.get("gauntlet", 0.0)
    if g > 0.0:                                     # Armoured cuff (flared towards the hand)
        p.lathe([(-0.16, 0, 0), (-0.17, 0.09 * g, 0.088 * g), (-0.3, 0.11 * g, 0.105 * g), (-0.37, 0.12 * g, 0.115 * g),
                 (-0.38, 0, 0)], k.get("gauntlet_mat", "hand"))
    # Hand: a closed fist (a rounded block) + thumb
    h = k.get("hand_size", 1.0)
    p.ellipsoid((0.03, 0, -0.44), (0.085 * h, 0.075 * h, 0.09 * h), "hand", rings=6)
    p.ellipsoid((0.09, -0.045, -0.41), (0.035 * h, 0.03 * h, 0.04 * h), "hand", seg=8, rings=4)
    return p


def chest(k):
    p = Part("chest")
    b = k.get("bulk", 1.0)
    w = k.get("width", 1.0)
    p.lathe([(-0.04, 0, 0), (-0.02, 0.15 * b, 0.22 * b * w), (0.06, 0.2 * b, 0.29 * b * w), (0.22, 0.2 * b, 0.28 * b * w),
             (0.34, 0.195 * b, 0.26 * b * w, 0.005), (0.52, 0.245 * b, 0.32 * b * w, 0.025), (0.7, 0.255 * b, 0.35 * b * w, 0.02),
             (0.8, 0.23 * b, 0.36 * b * w, 0.0), (0.88, 0.17 * b, 0.26 * b * w), (0.92, 0.1, 0.11), (1.0, 0.085, 0.085),
             (1.02, 0, 0)], "chest")
    # Belt: a band round the hips with a buckle
    p.lathe([(0.07, 0, 0), (0.075, 0.212 * b, 0.302 * b * w), (0.2, 0.207 * b, 0.292 * b * w), (0.205, 0, 0)], "belt")
    p.box((0.205 * b, 0, 0.137), (0.03, 0.11, 0.09), k.get("buckle", "belt"))
    return p


# ============================================================
# THE HEROES
# ============================================================
def warrior():
    k = {"limb": 1.0, "boot": 1.05, "gauntlet": 1.0, "gauntlet_mat": "hand", "boot_cuff": "belt", "knee_pad": "head_col",
         "buckle": "head_col"}
    parts = [thigh(k), shin(k), upperarm(k), forearm(k)]
    c = chest(k)
    # Chest plate ridge + shoulder pads (silver) on both shoulders
    c.shell([(0.36, 0.215, 0.27, 0.01), (0.52, 0.265, 0.335, 0.025), (0.7, 0.275, 0.365, 0.02), (0.8, 0.25, 0.375)],
            "head_col", -62, 62, 0.03)                                                             # Breastplate
    for side in (-1.0, 1.0):
        c.ellipsoid((-0.01, side * 0.43, 0.86), (0.15, 0.14, 0.11), "head_col", rings=7, flat_bottom=-0.04)
    parts.append(c)
    # Helmet: rounded dome, a jaw guard, a crest and two dark eye holes
    h = Part("head")
    h.lathe([(-0.2, 0, 0), (-0.19, 0.17, 0.17, 0.02), (-0.12, 0.23, 0.22, 0.02), (0.0, 0.255, 0.24), (0.12, 0.24, 0.225, -0.01),
             (0.21, 0.17, 0.16, -0.02), (0.26, 0.07, 0.07, -0.02), (0.27, 0, 0, -0.02)], "head_col")
    h.slab([(-0.24, 0.12), (-0.05, 0.31), (0.12, 0.3), (0.2, 0.22), (0.02, 0.24), (-0.18, 0.08)], 0.045, "belt")   # Crest
    for z in (-0.075, 0.075):
        h.ellipsoid((0.225, z, 0.03), (0.04, 0.045, 0.028), "dark", seg=10, rings=5)
    h.box((0.235, 0, -0.06), (0.03, 0.02, 0.12), "dark")                                                       # Breath slit
    parts.append(h)
    # Jagged sword (pointing +Z from the grip at the origin)
    s = Part("sword")
    blade = [(-0.05, 0.12), (0.05, 0.12), (0.06, 0.3), (0.035, 0.36), (0.065, 0.5), (0.04, 0.56), (0.07, 0.7), (0.045, 0.76),
             (0.06, 0.88), (0.0, 1.05), (-0.035, 0.9), (-0.045, 0.7), (-0.05, 0.4)]
    s.slab(blade, 0.03, "steel")
    s.box((0, 0, 0.1), (0.07, 0.24, 0.04), "head_col")                    # Cross guard
    s.lathe([(0.09, 0, 0), (0.085, 0.025, 0.025), (-0.08, 0.025, 0.025), (-0.09, 0, 0)], "grip", seg=8)
    s.ellipsoid((0, 0, -0.1), (0.035, 0.035, 0.035), "head_col", seg=8, rings=4)
    parts.append(s)
    return parts


def architect():
    k = {"limb": 0.95, "boot": 1.0, "gauntlet": 0.95, "gauntlet_mat": "chest", "boot_cuff": "chest", "width": 0.96,
         "buckle": "core"}
    parts = [thigh(k), shin(k), upperarm(k), forearm(k)]
    c = chest(k)
    # White armour plates: rounded shoulder caps + an abdomen plate, the glowing core sits in front
    for side in (-1.0, 1.0):
        c.ellipsoid((0.0, side * 0.42, 0.84), (0.13, 0.12, 0.1), "chest", rings=7, flat_bottom=-0.03)
    c.shell([(0.24, 0.215, 0.275), (0.34, 0.21, 0.27, 0.005), (0.42, 0.235, 0.3, 0.015)], "belt", -45, 45, 0.03)  # Abdomen plate
    c.ellipsoid((0.27, 0, 0.6), (0.05, 0.085, 0.085), "core")
    c.shell([(0.52, 0.258, 0.33, 0.025), (0.6, 0.27, 0.35, 0.025), (0.68, 0.27, 0.36, 0.02)], "belt", -30, 30, 0.03)
    c.shell([(0.52, 0.258, 0.33, 0.025), (0.6, 0.27, 0.35, 0.025), (0.68, 0.27, 0.36, 0.02)], "chest", -62, -30, 0.03)
    c.shell([(0.52, 0.258, 0.33, 0.025), (0.6, 0.27, 0.35, 0.025), (0.68, 0.27, 0.36, 0.02)], "chest", 30, 62, 0.03)
    parts.append(c)
    # Smooth helmet with a wide dark visor wrapping the front
    h = Part("head")
    h.lathe([(-0.2, 0, 0), (-0.19, 0.16, 0.16, 0.02), (-0.1, 0.235, 0.22, 0.02), (0.02, 0.255, 0.235), (0.14, 0.235, 0.215, -0.015),
             (0.22, 0.15, 0.14, -0.02), (0.255, 0, 0, -0.02)], "head_col")
    h.shell([(-0.06, 0.25, 0.232, 0.01), (0.02, 0.27, 0.25), (0.09, 0.262, 0.24, -0.005)], "visor", -78, 78, 0.03, 14)
    h.box((0.0, 0.0, 0.215), (0.2, 0.04, 0.06), "belt")              # Top ridge
    parts.append(h)
    return parts


def enlightened():
    k = {"limb": 0.95, "boot": 0.95, "gauntlet": 1.35, "gauntlet_mat": "hand", "hand_size": 1.15, "boot_cuff": "chest",
         "buckle": "chest", "width": 0.95}
    parts = [thigh(k), shin(k), upperarm(k), forearm(k)]
    c = chest(k)
    # A gold tabard: a front + back panel hanging from the belt, and a high collar
    tab = [(0.1, 0.215, 0.3), (-0.06, 0.24, 0.31), (-0.2, 0.27, 0.32)]
    c.shell(tab, "chest", -40, 40, 0.025)                              # Front + back panels of the tabard
    c.shell(tab, "chest", 140, 220, 0.025)
    c.shell([(0.3, 0.205, 0.27, 0.005), (0.5, 0.255, 0.325, 0.025), (0.72, 0.265, 0.36, 0.02), (0.82, 0.24, 0.37)],
            "belt", -16, 16, 0.03)                                     # Bronze sash down the chest
    c.lathe([(0.84, 0, 0), (0.85, 0.15, 0.2), (0.96, 0.13, 0.16), (0.97, 0, 0)], "belt")
    for side in (-1.0, 1.0):
        c.ellipsoid((0.0, side * 0.41, 0.83), (0.12, 0.12, 0.09), "belt", rings=7, flat_bottom=-0.02)
    parts.append(c)
    # A smooth ivory mask-face: an egg-shaped head, a nose ridge, two glowing gold eye slits
    h = Part("head")
    h.lathe([(-0.21, 0, 0), (-0.2, 0.12, 0.13, 0.03), (-0.1, 0.21, 0.2, 0.02), (0.03, 0.24, 0.22), (0.15, 0.22, 0.2, -0.01),
             (0.23, 0.13, 0.12, -0.02), (0.255, 0, 0, -0.02)], "leg")             # Dark hood behind the mask
    h.shell([(-0.17, 0.2, 0.19, 0.035), (-0.06, 0.245, 0.225, 0.02), (0.06, 0.255, 0.23, 0.005), (0.17, 0.215, 0.2, -0.01)],
            "head_col", -70, 70, 0.03, 12)                             # The mask over the face
    h.slab([(0.25, 0.05), (0.29, -0.05), (0.25, -0.08)], 0.03, "head_col")     # Nose ridge
    for z in (-0.08, 0.08):
        h.box((0.255, z, 0.03), (0.03, 0.07, 0.024), "eye_gold")
    parts.append(h)
    return parts


HEROES = {
    "warrior": (warrior, {"leg": (0.16, 0.12, 0.26), "chest": (0.16, 0.12, 0.26), "arm": (0.16, 0.12, 0.26),
                          "belt": (0.32, 0.25, 0.48), "head_col": (0.78, 0.80, 0.86)}),
    "architect": (architect, {"leg": (0.25, 0.62, 0.38), "arm": (0.25, 0.62, 0.38), "chest": (0.92, 0.93, 0.95),
                              "belt": (0.18, 0.2, 0.24), "foot": (0.12, 0.13, 0.16), "hand": (0.18, 0.45, 0.28),
                              "head_col": (0.92, 0.93, 0.95)}),
    "enlightened": (enlightened, {"leg": (0.2, 0.17, 0.3), "arm": (0.2, 0.17, 0.3), "chest": (0.97, 0.77, 0.24),
                                  "belt": (0.68, 0.48, 0.12), "foot": (0.97, 0.77, 0.24), "hand": (0.74, 0.46, 0.2),
                                  "head_col": (0.96, 0.93, 0.84)}),
}

# Where each part sits in the preview (the same joints as Hero3D): Blender coords, feet at 0
HIP = 0.95


def place(name, side):
    y = -side * 0.16                                                   # Near side = -Y
    sz = 0.3 * 1.15 + 0.105 + 0.03
    return {
        "thigh": (0, y, HIP), "shin": (0, y, HIP - 0.475),
        "upperarm": (0, -side * sz, HIP + 0.8), "forearm": (0, -side * sz, HIP + 0.8 - 0.425),
        "chest": (0, 0, HIP), "head": (0.02, 0, HIP + 1.08),
    }.get(name)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export(who, out_dir):
    reset()
    _preview_override.clear()
    fn, cols = HEROES[who]
    _preview_override.update(cols)
    coll = bpy.context.scene.collection
    obs = [p.build(coll) for p in fn()]
    path = os.path.join(out_dir, who + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False, export_apply=True,
                              export_materials="EXPORT", export_normals=True, export_yup=True)
    tris = sum(sum(len(pl.vertices) - 2 for pl in o.data.polygons) for o in obs)
    print("HERO %s -> %s (%d parts, %d tris, %.0f KB)" % (who, path, len(obs), tris, os.path.getsize(path) / 1024))
    return obs


def preview(who, obs, prev_dir):
    """Assemble the parts in a standing pose, add a black inverted-hull outline, render 2 views."""
    by = {o.name: o for o in obs}
    scene = bpy.context.scene
    for name, o in list(by.items()):
        if name == "sword":
            continue
        sides = [1.0, -1.0] if name in ("thigh", "shin", "upperarm", "forearm") else [1.0]
        for side in sides:
            ob = o if side > 0 else o.copy()
            if side < 0:
                ob.data = o.data.copy()
                scene.collection.objects.link(ob)
            ob.location = place(name, side)
            if name == "upperarm":
                ob.rotation_euler = (side * 0.1, 0.0, 0.0)
    if "sword" in by:                                                  # In the near hand, pointing forward-down
        s = by["sword"]
        s.location = (0.1, -0.52, HIP + 0.8 - 0.85)
        s.rotation_euler = (0.0, math.radians(110), 0.0)
    black = bpy.data.materials.new("outline")
    black.use_nodes = True
    black.use_backface_culling = True
    bs = black.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (0, 0, 0, 1)
    bs.inputs["Roughness"].default_value = 1.0
    for ob in [o for o in scene.objects if o.type == "MESH"]:
        ob.data.materials.append(black)
        mod = ob.modifiers.new("outline", "SOLIDIFY")
        mod.thickness = 0.022
        mod.offset = 1.0
        mod.use_flip_normals = True
        mod.material_offset = len(ob.data.materials) - 1
    bpy.ops.object.light_add(type="SUN", location=(3, -3, 5))
    sun = bpy.context.object
    sun.data.energy = 3.5
    sun.rotation_euler = (Vector((0, 0, 0)) - Vector((4, -5, 5))).to_track_quat("-Z", "Y").to_euler()
    scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.38, 0.45, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = 70
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 800
    scene.render.film_transparent = False
    for tag, ang in (("front", -55.0), ("side", -95.0)):
        a = math.radians(ang)
        cam.location = (math.cos(a) * -6.0 * -1, math.sin(a) * 6.0, 1.5)
        direction = Vector((0, 0, 1.15)) - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(prev_dir, "hero_%s_%s.png" % (who, tag))
        bpy.ops.render.render(write_still=True)
        print("PREVIEW", scene.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = os.path.abspath(argv[0] if argv else "art/models/heroes")
    prev_dir = os.path.abspath(argv[1]) if len(argv) > 1 else ""
    os.makedirs(out_dir, exist_ok=True)
    for who in HEROES:
        obs = export(who, out_dir)
        if prev_dir:
            os.makedirs(prev_dir, exist_ok=True)
            preview(who, obs, prev_dir)


main()
