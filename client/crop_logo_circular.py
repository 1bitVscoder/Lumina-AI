from PIL import Image, ImageDraw
import os

img_path = r"C:\Users\soumya\.gemini\antigravity-ide\brain\b82c0b17-405a-4ae0-9e6b-4964f00ca70f\media__1781534324798.png"
dest_path = r"c:\Users\soumya\.gemini\antigravity\scratch\Lumina\client\assets\lumina_logo.png"

if os.path.exists(img_path):
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Square size will be the height of the image (symmetrical crop along horizontal axis)
    size = min(width, height)
    left = (width - size) // 2
    top = (height - size) // 2
    right = left + size
    bottom = top + size
    
    cropped = img.crop((left, top, right, bottom))
    
    # Create a circular mask
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size, size), fill=255)
    
    # Create transparent background image and paste the cropped logo inside the circle
    circular_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    circular_img.paste(cropped, (0, 0), mask=mask)
    
    # Resize to standard high-res logo size (512x512) for launcher icons
    resized = circular_img.resize((512, 512), Image.Resampling.LANCZOS)
    
    # Save the circular logo
    resized.save(dest_path, "PNG")
    print("Circular logo cropped and saved successfully!")
else:
    print(f"Error: Source image not found at {img_path}")
