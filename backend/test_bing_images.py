import requests
import re
import html

def extract_all_images(query):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    }
    url = f"https://www.bing.com/images/search?q={query.replace(' ', '+')}"
    try:
        r = requests.get(url, headers=headers, timeout=10)
        decoded_html = html.unescape(r.text)
        
        # Regex to find any HTTP/HTTPS link ending in common image extensions
        # We look for matches inside quotes
        matches = re.findall(r'"(https?://[^"]+\.(?:jpg|jpeg|png|webp))"', decoded_html, re.IGNORECASE)
        print(f"Total image URLs found for '{query}': {len(matches)}")
        for i, m in enumerate(matches[:15]):
            print(f"{i+1}: {m}")
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    extract_all_images("Samsung Galaxy S24 Ultra")
