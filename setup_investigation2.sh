import os
import subprocess

# Define the structure you want
required_dirs = ['assets', 'case_data', 'logs']

def bootstrap():
    for folder in required_dirs:
        if not os.path.exists(folder):
            print(f"Recreating missing directory: {folder}")
            os.makedirs(folder)

if __name__ == "__main__":
    bootstrap()
    print("Starting Artifacts Server on port 8009...")
    # This launches the standard server after ensuring folders exist
    subprocess.run(["python3", "-m", "http.server", "8009"])