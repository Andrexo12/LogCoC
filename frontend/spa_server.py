import http.server
import socketserver
import os
import sys

PORT = 5050
# Ensure we are in the frontend directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = os.path.join(os.getcwd(), "build", "web")

class SPADirectoryHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Serve files directly from WEB_DIR
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_GET(self):
        # Translate path relative to WEB_DIR
        path = self.translate_path(self.path)
        if not os.path.exists(path) or os.path.isdir(path):
            # Fallback to index.html for SPA routing
            self.path = "/index.html"
        return super().do_GET()

print(f"Serving SPA from {WEB_DIR} at port {PORT}")
try:
    # Use ThreadingTCPServer to avoid blocking on concurrent assets requests
    with socketserver.ThreadingTCPServer(("", PORT), SPADirectoryHandler) as httpd:
        httpd.serve_forever()
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
