import requests
import subprocess
import argparse
from urllib.parse import unquote
import os

# Command-line argument parsing
parser = argparse.ArgumentParser(description="Script for interacting with Kodi and Pixlet API")
parser.add_argument("PixletApiKey", help="API key for Pixlet")
parser.add_argument(
    "ArtType", 
    choices=["T", "F", "B", "L"], 
    help="Specify 'T' for thumbnail, 'F' for fanart, 'B' for banner, or 'L' for clearlogo"
)
args = parser.parse_args()

# Replace these with your Kodi server details
kodi_host = "http://192.168.150.93:8080"
kodi_username = "kodi"
kodi_password = "k"

# Endpoint for getting the currently playing item details
endpoint = "/jsonrpc"
url = f"{kodi_host}{endpoint}"

# JSON-RPC request payload to get player item details
kodi_payload = {
    "jsonrpc": "2.0",
    "method": "Player.GetItem",
    "params": {
        "properties": ["title", "showtitle", "season", "episode", "art"],
        "playerid": 1,  # Assuming video player is playerid 1
    },
    "id": 1,
}

# Add authentication if required
auth = (kodi_username, kodi_password) if kodi_username and kodi_password else None

# Make the request
response = requests.post(url, json=kodi_payload, auth=auth)

# Check if the request was successful
if response.status_code == 200:
    result = response.json().get("result", {})
    item = result.get("item", {})
    art_urls = item.get("art", {})
    show_episode = item.get("label", "")
    show_series = item.get("showtitle", "")
else:
    print(f"Error: {response.status_code}, {response.text}")
    exit(1)

# Function to clean and map artwork URLs
def clean_art_url(url):
    if url.startswith("image://"):
        url = unquote(url[8:])  # Remove "image://"
    if url.startswith("special://home"):
        url = url.replace("special://home", "/storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi")
    if url.endswith("/"):
        url = url[:-1]  # Remove trailing "/"
    return url

# Determine artwork to use based on command-line argument
if args.ArtType == "T" and "thumbnail" in art_urls:
    print("Using Thumbnail")
    art = clean_art_url(unquote(art_urls["thumbnail"]))
elif args.ArtType == "F" and "fanart" in art_urls:
    print("Using Fanart")
    art = clean_art_url(unquote(art_urls["fanart"]))
elif args.ArtType == "B" and "banner" in art_urls:
    print("Using Banner")
    art = clean_art_url(unquote(art_urls["banner"]))
elif args.ArtType == "L" and "clearlogo" in art_urls:
    print("Using ClearLogo")
    art = clean_art_url(unquote(art_urls["clearlogo"]))
else:
    # Fallback case
    print("Art type not available or invalid. Using default.")
    art = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

# Check if the local artwork exists
#if not art.startswith("http") and not os.path.exists(art):
#    print(f"Artwork not found locally: {art}. Using fallback URL.")
#    art = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

print("Using art:", art)
print("Label Found:", show_series)

# Fire off Pixlet
if not show_episode:
    show_episode = "Player Idle"

tidBytMarquee = f"Now Playing - {show_series} : {show_episode}".replace("'", "")

cliArg1 = f"pixlet render /home/cd12172/Public/hass_nowplaying.star ArtUrl='{art}' NowPlaying='{tidBytMarquee}'"
cliArg2 = f"pixlet push {args.PixletApiKey} /home/cd12172/Public/hass_nowplaying.webp"
#cliArg3 = f"pixlet  serve /home/cd12172/Public/hass_nowplaying.star ArtUrl='{art}' NowPlaying='{tidBytMarquee}'"

print(cliArg1)
print(cliArg2)
#print(cliArg3)

# Run Pixlet commands
subprocess.run(cliArg1, shell=True, capture_output=False)
subprocess.run(cliArg2, shell=True, capture_output=False)
#subprocess.run(cliArg3, shell=True, capture_output=False)
