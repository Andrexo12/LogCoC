import requests

def get_ddg_instant_image(query):
    url = "https://api.duckduckgo.com/"
    params = {
        "q": query,
        "format": "json",
        "no_redirect": 1,
        "no_html": 1
    }
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    try:
        r = requests.get(url, params=params, headers=headers, timeout=10)
        if r.status_code == 200:
            data = r.json()
            image_path = data.get("Image")
            if image_path:
                if image_path.startswith("/"):
                    return f"https://duckduckgo.com{image_path}"
                return image_path
            
            # Check if there is an abstract image in the Topic/Results
            related = data.get("RelatedTopics", [])
            for topic in related:
                icon = topic.get("Icon", {})
                if icon and icon.get("URL"):
                    img_url = icon.get("URL")
                    if img_url.startswith("/"):
                        return f"https://duckduckgo.com{img_url}"
                    return img_url
        return None
    except Exception as e:
        print("Error:", e)
        return None

if __name__ == "__main__":
    products = [
        "Samsung Galaxy S24 Ultra",
        "Apple iPhone 15 Pro",
        "Xiaomi Redmi Note 13",
        "Xiaomi watch 5 lite"
    ]
    for p in products:
        print(f"Product: '{p}' -> Image: '{get_ddg_instant_image(p)}'")
