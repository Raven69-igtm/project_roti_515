import xml.etree.ElementTree as ET

def create_node(root, node_id, value, style, x, y, width, height):
    cell = ET.SubElement(root, "mxCell", id=node_id, value=value, style=style, vertex="1", parent="1")
    ET.SubElement(cell, "mxGeometry", x=str(x), y=str(y), width=str(width), height=str(height), **{"as": "geometry"})
    return cell

def create_edge(root, edge_id, label, source, target):
    style = "endArrow=none;html=1;endFill=0;labelBackgroundColor=none;"
    cell = ET.SubElement(root, "mxCell", id=edge_id, value=label, style=style, edge="1", parent="1", source=source, target=target)
    ET.SubElement(cell, "mxGeometry", relative="1", **{"as": "geometry"})
    return cell

mxfile = ET.Element("mxfile", host="app.diagrams.net", type="device", version="21.0.0")
diagram = ET.SubElement(mxfile, "diagram", id="ERD-Chen", name="ERD Roti 515")
model = ET.SubElement(diagram, "mxGraphModel", dx="1422", dy="762", grid="1", gridSize="10", guides="1", tooltips="1", connect="1", arrows="1", fold="1", page="1", pageScale="1", pageWidth="1600", pageHeight="1200", math="0", shadow="0")
root = ET.SubElement(model, "root")
ET.SubElement(root, "mxCell", id="0")
ET.SubElement(root, "mxCell", id="1", parent="0")

ent_style = "shape=rectangle;whiteSpace=wrap;html=1;align=center;fontStyle=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
attr_style = "shape=ellipse;whiteSpace=wrap;html=1;align=center;fillColor=#f8cecc;strokeColor=#b85450;"
rel_style = "shape=rhombus;whiteSpace=wrap;html=1;align=center;fillColor=#d5e8d4;strokeColor=#82b366;"

# Entities
entities = {
    "USER": (200, 200, [("id", True), "nama", "email", "password"]),
    "ADMIN": (500, 50, [("id", True)]),
    "PELANGGAN": (500, 200, [("id", True), "no_hp", "tgl_daftar"]),
    "NOTIFICATION": (200, 500, [("id", True), "user_id", "title", "message", "is_read", "created_at"]),
    "RATING": (500, 800, [("id", True), "user_id", "product_id", "order_id", "rating", "comment"]),
    "KERANJANG": (500, 400, [("id", True), "pelanggan_id"]),
    "ORDER": (900, 200, [("id", True), "pelanggan_id", "jadwal_ambil_id", "status", "total", "metode_bayar"]),
    "JADWAL_AMBIL": (1300, 100, [("id", True), "jam_mulai", "jam_selesai", "is_aktif"]),
    "ORDER_DETAIL": (900, 500, [("id", True), "order_id", "produk_id", "jumlah", "harga_satuan"]),
    "KERANJANG_DETAIL": (900, 700, [("id", True), "keranjang_id", "produk_id", "jumlah"]),
    "PRODUK": (1300, 600, [("id", True), "nama", "harga", "gambar", "stok"])
}

# Add Entities & Attributes
for ent, (x, y, attrs) in entities.items():
    create_node(root, "ent_"+ent, ent, ent_style, x, y, 120, 60)
    for i, attr in enumerate(attrs):
        is_pk = False
        if isinstance(attr, tuple):
            attr_name, is_pk = attr
        else:
            attr_name = attr
        
        display_name = f"&lt;u&gt;{attr_name}&lt;/u&gt;" if is_pk else attr_name
        
        # position in a circle around entity
        import math
        angle = (i / len(attrs)) * 2 * math.pi
        ax = x + 30 + 100 * math.cos(angle)
        ay = y + 10 + 80 * math.sin(angle)
        
        attr_id = f"attr_{ent}_{attr_name}"
        create_node(root, attr_id, display_name, attr_style, ax, ay, 80, 40)
        create_edge(root, f"line_{ent}_{attr_name}", "", f"ent_{ent}", attr_id)

# Relationships
relations = [
    ("USER", "ADMIN", "1", "1", "is_a_admin"),
    ("USER", "PELANGGAN", "1", "1", "is_a_pelanggan"),
    ("USER", "NOTIFICATION", "1", "N", "receives"),
    ("USER", "RATING", "1", "N", "gives_rating"),
    ("PELANGGAN", "KERANJANG", "1", "1", "has_cart"),
    ("PELANGGAN", "ORDER", "1", "N", "places_order"),
    ("JADWAL_AMBIL", "ORDER", "1", "N", "scheduled_for"),
    ("KERANJANG", "KERANJANG_DETAIL", "1", "N", "contains_cart"),
    ("ORDER", "ORDER_DETAIL", "1", "N", "contains_order"),
    ("PRODUK", "KERANJANG_DETAIL", "1", "N", "in_cart"),
    ("PRODUK", "ORDER_DETAIL", "1", "N", "in_order"),
    ("PRODUK", "RATING", "1", "N", "receives_rating")
]

for idx, (e1, e2, card1, card2, rel_name) in enumerate(relations):
    x1, y1, _ = entities[e1]
    x2, y2, _ = entities[e2]
    rx, ry = (x1 + x2) / 2 + 10, (y1 + y2) / 2 + 10
    
    rel_id = f"rel_{idx}"
    create_node(root, rel_id, rel_name.replace("_", " "), rel_style, rx, ry, 100, 60)
    create_edge(root, f"line_r1_{idx}", card1, f"ent_{e1}", rel_id)
    create_edge(root, f"line_r2_{idx}", card2, rel_id, f"ent_{e2}")

tree = ET.ElementTree(mxfile)
with open("erd_final_roti515.drawio", "wb") as f:
    f.write(b"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    tree.write(f, encoding="utf-8")
