import os
import subprocess

def send_ipc_command(command: str) -> bool:
    """Send an IPC command to OgsShell named pipe or execute shell/ipc.sh."""
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    pipe_path = os.path.join(runtime_dir, "ogsshell-ipc")

    if os.path.exists(pipe_path):
        try:
            with open(pipe_path, "w") as f:
                f.write(command + "\n")
            return True
        except Exception as e:
            print(f"[IPCClient] Pipe write failed: {e}")

    # Fallback to shell script
    script_path = os.path.expanduser("~/WorkSpace/projects/OgsShell-qs/shell/ipc.sh")
    if os.path.exists(script_path):
        try:
            subprocess.run(["bash", script_path, command], timeout=1, check=False)
            return True
        except Exception as e:
            print(f"[IPCClient] Script exec failed: {e}")

    return False
