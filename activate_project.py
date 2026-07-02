# activate_project.py
"""Utility to start the LogCoC backend and Flutter frontend.
Ensures that the default ports (8000 for FastAPI and 5000 for Flutter Web) are free.
If a process is already listening on either port, it will be terminated before
starting the services.
"""
import os
import signal
import subprocess
import sys
import shutil
import time
from typing import List

def _pids_on_port(port: int) -> List[int]:
    """Return a list of PIDs listening on the given TCP port.
    Uses `lsof` which is available in most Linux containers.
    """
    try:
        result = subprocess.run(["lsof", "-i", f":{port}", "-t"], capture_output=True, text=True, check=False)
        if result.stdout:
            return [int(pid) for pid in result.stdout.strip().splitlines()]
    except FileNotFoundError:
        # lsof not installed – fall back to netstat/ss (not needed for this CI env)
        pass
    return []

def _kill_pids(pids: List[int]):
    """Terminate the given PIDs gracefully, falling back to SIGKILL if needed."""
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            continue
    # Give a moment for processes to exit
    time.sleep(1)
    # Force kill any that remain
    for pid in pids:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            continue

def _ensure_port_free(port: int):
    """Make sure *port* is not bound; kill any process that is using it."""
    pids = _pids_on_port(port)
    if pids:
        print(f"Port {port} is in use by PID(s) {pids}. Terminating…")
        _kill_pids(pids)
        # Verify again
        if _pids_on_port(port):
            print(f"Failed to free port {port}. Exiting.")
            sys.exit(1)
    else:
        print(f"Port {port} is free.")

def _run_backend():
    """Start the FastAPI backend using uvicorn in a subprocess.
    The process runs in the foreground of this script so you can stop it with Ctrl‑C.
    """
    backend_cmd = ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
    print("Starting backend…")
    return subprocess.Popen(backend_cmd, cwd=os.path.join(os.getcwd(), "backend"))

def _run_frontend():
    """Serve the pre‑built Flutter web assets using a simple Python HTTP server.
    The assets are expected in `frontend/build/web`. This avoids dependence on a
    local Flutter installation and works reliably in the Codespaces environment.
    """
    static_dir = os.path.join(os.getcwd(), "frontend", "build", "web")
    if not os.path.isdir(static_dir):
        print("Error: No pre‑built web assets found in 'frontend/build/web'.")
        sys.exit(1)
    http_cmd = ["python", "-m", "http.server", "5000", "--bind", "0.0.0.0", "--directory", static_dir]
    print("Starting frontend via Python HTTP server…")
    return subprocess.Popen(http_cmd, cwd=os.getcwd())

def activate_project():
    """Free required ports and start both backend and frontend.
    The function blocks until you interrupt it (Ctrl‑C), at which point it will
    terminate the spawned processes.
    """
    required_ports = [8000, 5000]
    for p in required_ports:
        _ensure_port_free(p)

    # Launch services
    backend_proc = _run_backend()
    frontend_proc = _run_frontend()

    try:
        # Wait for both processes; they will keep running until the user stops the script
        while True:
            time.sleep(1)
            # Simple health check – if any process exits unexpectedly, break out
            if backend_proc.poll() is not None:
                print("Backend process exited. Stopping frontend.")
                break
            if frontend_proc.poll() is not None:
                print("Frontend process exited. Stopping backend.")
                break
    except KeyboardInterrupt:
        print("Interrupted – shutting down services…")
    finally:
        for proc, name in [(backend_proc, "backend"), (frontend_proc, "frontend")]:
            if proc and proc.poll() is None:
                print(f"Terminating {name}…")
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
        print("All services stopped.")

if __name__ == "__main__":
    activate_project()
