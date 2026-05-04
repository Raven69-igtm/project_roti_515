import os
from PIL import Image

image_dir = r"c:\project_roti_515\assets\images"
image_names = [
    "daftar.png",
    "login.png",
    "Cari Produk.png",
    "produk_pelanggan.png",
    "detail_menu.png",
    "keranjang.png",
    "checkout_roti515.png",
    "Pesanan Berhasil.png",
    "pelanggan terima notfikasi.png",
    "riwayat_pesanan dan batalkan pesanan.png",
    "dashboard_admin.png",
    "admin atur jam pengembalian.png",
    "kelola_produk_admin.png",
    "kelola_akun_admin.png"
]

images = []
for name in image_names:
    path = os.path.join(image_dir, name)
    if os.path.exists(path):
        img = Image.open(path).convert("RGBA")
        images.append(img)
    else:
        print(f"Missing: {path}")

if not images:
    print("No images found.")
    exit()

# Resize all images to the same height (e.g. 800px)
target_height = 800
resized_images = []
for img in images:
    width = int((target_height / img.height) * img.width)
    resized_images.append(img.resize((width, target_height), Image.Resampling.LANCZOS))

# 2 rows, 7 columns
cols = 7
rows = 2
padding = 40

# Calculate row widths and heights
row_widths = []
for r in range(rows):
    w = sum(img.width for img in resized_images[r*cols:(r+1)*cols]) + padding * (cols + 1)
    row_widths.append(w)

max_width = max(row_widths)
total_height = (target_height * rows) + padding * (rows + 1)

# Create blank canvas (white)
canvas = Image.new("RGB", (max_width, total_height), "white")

# Paste images
y_offset = padding
for r in range(rows):
    x_offset = padding
    row_imgs = resized_images[r*cols:(r+1)*cols]
    
    # center row if it's shorter
    x_offset = (max_width - (sum(img.width for img in row_imgs) + padding * (len(row_imgs) - 1))) // 2
    
    for img in row_imgs:
        canvas.paste(img, (x_offset, y_offset), img)
        x_offset += img.width + padding
    y_offset += target_height + padding

out_path = r"c:\project_roti_515\assets\images\collage_all.png"
canvas.save(out_path)
print(f"Saved collage to {out_path}")
