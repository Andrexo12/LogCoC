import http.server
import socketserver
import os
import sys

PORT = 5000
# Ensure we are in the frontend directory to find build/web
os.chdir(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = os.path.join(os.getcwd(), "build", "web")

class SPADirectoryHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Always serve files from WEB_DIR
        original_path = super().translate_path(path)
        # Convert to relative path from the current working directory (which is where the script is)
        rel_path = os.path.relpath(original_path, os.getcwd())
        
        # Check if it points to build/web
        if not rel_path.startswith("build/web"):
            # If not, force it to be under build/web
            target = os.path.join(WEB_DIR, path.lstrip("/"))
        else:
            target = original_path

        if not os.path.exists(target) or os.path.isdir(target):
            return os.path.join(WEB_DIR, "index.html")
        return target

print(f"Serving SPA from {WEB_DIR} at port {PORT}")
try:
    with socketserver.TCPServer(("", PORT), SPADirectoryHandler) as httpd:
        httpd.serve_forever()
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
