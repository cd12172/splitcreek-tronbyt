import requests
import argparse
from urllib.parse import unquote

# Command-line argument parsing
parser = argparse.ArgumentParser(description="Get Artwork links from Kodi")
parser.add_argument(
    "ArtType", 
    choices=["T", "F", "B", "L"], 
    help="T=thumbnail, F=fanart, B=banner, L=clearlogo"
)
args = parser.parse_args()

# Kodi server details
kodi_host = "http://192.168.150.194:8080"
kodi_username = "kodi"
kodi_password = "k"

url = f"{kodi_host}/jsonrpc"
kodi_payload = {
    "jsonrpc": "2.0",
    "method": "Player.GetItem",
    "params": {
        "properties": ["art"],
        "playerid": 1,
    },
    "id": 1,
}

auth = (kodi_username, kodi_password)

def clean_art_url(url):
    if url.startswith("image://"):
        # Kodi encodes the actual URL inside the image:// wrapper
        url = unquote(url[8:])
    if url.endswith("/"):
        url = url[:-1]
    return url

try:
    response = requests.post(url, json=kodi_payload, auth=auth)
    if response.status_code == 200:
        result = response.json().get("result", {})
        art_urls = result.get("item", {}).get("art", {})
        
        mapping = {"T": "thumbnail", "F": "fanart", "B": "banner", "L": "clearlogo"}
        target = mapping.get(args.ArtType)
        
        if target in art_urls:
            raw_url = art_urls[target]
            print(clean_art_url(raw_url))
        else:
            print("ERROR: Requested art type not found for this item.")
    else:
        print(f"ERROR: Kodi returned status {response.status_code}")
except Exception as e:
    print(f"ERROR: Could not connect to Kodi: {e}")