import os
from PIL import Image, ImageDraw, ImageFont

def create_collage():
    image_dir = r"c:\project_roti_515\assets\images"
    image_files = [
        "daftar.png",
        "login.png",
        "home.png",
        "Cari Produk.png",
        "detail_menu.png",
        "keranjang.png",
        "checkout_roti515.png",
        "Pesanan Berhasil.png",
        "riwayat_pesanan dan batalkan pesanan.png",
        "produk_pelanggan.png",
        "pelanggan terima notfikasi.png",
        "dashboard_admin.png",
        "kelola_produk_admin.png",
        "kelola_akun_admin.png",
        "admin atur jam pengembalian.png"
    ]

    images = []
    for file in image_files:
        path = os.path.join(image_dir, file)
        if os.path.exists(path):
            try:
                img = Image.open(path)
                images.append(img)
            except Exception as e:
                print(f"Error opening {file}: {e}")
        else:
            print(f"File not found: {file}")

    if not images:
        print("No images found.")
        return

    # Resize all images to the same height, while maintaining aspect ratio, or scale to specific width
    # Most of these are mobile app screens, except maybe admin ones.
    target_width = 300
    target_height = 650

    resized_images = []
    for img in images:
        # We can crop or pad them to be exactly target_width x target_height, or just resize
        img_ratio = img.width / img.height
        target_ratio = target_width / target_height
        
        if img_ratio > target_ratio:
            # wider
            new_height = int(target_width / img_ratio)
            img = img.resize((target_width, new_height), Image.Resampling.LANCZOS)
        else:
            # taller
            new_width = int(target_height * img_ratio)
            img = img.resize((new_width, target_height), Image.Resampling.LANCZOS)
            
        # Create a blank white canvas of target size and paste the image in the center
        new_img = Image.new('RGBA', (target_width, target_height), (255, 255, 255, 0))
        paste_x = (target_width - img.width) // 2
        paste_y = (target_height - img.height) // 2
        new_img.paste(img, (paste_x, paste_y))
        resized_images.append(new_img)

    # Grid layout: 8 columns x 2 rows = 16 (we have 15 images)
    cols = 8
    rows = 2
    margin = 50
    padding = 30
    
    # Optional: Title space at the top
    title_height = 100
    
    canvas_width = margin * 2 + cols * target_width + (cols - 1) * padding
    canvas_height = margin * 2 + rows * target_height + (rows - 1) * padding + title_height

    # Clean white background
    canvas = Image.new('RGB', (canvas_width, canvas_height), (255, 255, 255))
    draw = ImageDraw.Draw(canvas)

    # Adding a simple title
    # We will try to use a default font if custom font is not available
    try:
        font = ImageFont.truetype("arial.ttf", 60)
    except:
        font = ImageFont.load_default()

    title_text = "Roti 515 - High Fidelity Design"
    
    # Calculate bounding box of text for centering
    bbox = draw.textbbox((0, 0), title_text, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (canvas_width - text_width) // 2
    draw.text((text_x, margin), title_text, font=font, fill=(0, 0, 0))

    # Paste images
    for i, img in enumerate(resized_images):
        row = i // cols
        col = i % cols
        
        x = margin + col * (target_width + padding)
        y = margin + title_height + row * (target_height + padding)
        
        # Adding a subtle shadow could be nice, but simple paste is fine
        canvas.paste(img, (x, y), img)

    output_path = os.path.join(image_dir, "hifi_presentation.png")
    canvas.save(output_path)
    print(f"Collage saved to {output_path}")

if __name__ == '__main__':
    create_collage()
