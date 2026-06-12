import requests

def search_qwant_image(query):
    # Qwant API requires a specific User-Agent to avoid blocking
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
        "Accept": "application/json"
    }
    url = "https://api.qwant.com/v3/search/images"
    params = {
        "q": query,
        "count": 5,
        "t": "images",
        "safesearch": 1,
        "locale": "es_ES"
    }
    try:
        r = requests.get(url, headers=headers, params=params, timeout=10)
        print("Status code:", r.status_code)
        if r.status_code == 200:
            data = r.json()
            items = data.get("data", {}).get("result", {}).get("items", [])
            print(f"Found {len(items)} items in Qwant.")
            for i, item in enumerate(items):
                print(f"{i+1}: {item.get('media')} - {item.get('title')}")
            if items:
                return items[0].get("media")
        else:
            print("Response:", r.text[:200])
        return None
    except Exception as e:
        print("Error:", e)
        return None

if __name__ == "__main__":
    print("S24 Ultra image:", search_qwant_image("Samsung Galaxy S24 Ultra"))
    print("Redmi Note 13 image:", search_qwant_image("Xiaomi Redmi Note 13"))
