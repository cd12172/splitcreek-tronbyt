load("http.star", "http")
load("render.star", "render")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

# --- CONFIG ---
# Double check: Is it .93 or .194? Use the one that worked in your Python test!
KODI_IP = "192.168.150.194:8080" 
KODI_URL = "http://%s/jsonrpc" % KODI_IP
AUTH = "Basic a29kaTpr" 
DEFAULT_ART = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

def clean_url(url_string):
    """
    Manually decodes the most common URL characters to stop Pixlet 
    from seeing '%' signs and throwing formatting errors.
    """
    u = url_string
    u = u.replace("%3A", ":").replace("%3a", ":")
    u = u.replace("%2F", "/").replace("%2f", "/")
    u = u.replace("%2E", ".").replace("%2e", ".")
    return u

def main(config):
    # 1. Ask Kodi what is playing
    res = http.post(
        url = KODI_URL,
        headers = {"Authorization": AUTH},
        body = json.encode({
            "jsonrpc": "2.0",
            "method": "Player.GetItem",
            "params": {"properties": ["title", "showtitle", "art"], "playerid": 1},
            "id": 1,
        }),
    )

    title_text = "Kodi Idle"
    art_data = None

    if res.status_code == 200:
        result_json = res.json()
        item = result_json.get("result", {}).get("item", {})
        
        # Build the Title Text
        st = item.get("showtitle", "")
        ti = item.get("title", "")
        if st and ti:
            title_text = "%s: %s" % (st, ti)
        elif ti:
            title_text = ti
        elif item.get("label"):
            title_text = item.get("label")

        # Handle Artwork
        art_map = item.get("art", {})
        priorities = ["clearlogo", "banner", "poster", "thumb", "thumbnail", "fanart"]
        
        raw_target = ""
        for key in priorities:
            if art_map.get(key):
                raw_target = art_map[key]
                print("Selected Art Type: " + key)
                break

        if raw_target:
            # Clean the URL to remove the % encoding that crashes Pixlet
            target = clean_url(raw_target)
            
            if "http" in target:
                # OPTION A: It's a web link (TMDB, etc)
                # Find where 'http' actually starts and ignore 'image://'
                start_index = target.find("http")
                final_url = target[start_index:]
                
                if final_url.endswith("/"):
                    final_url = final_url[:-1]
                
                print("Fetching Web Art: " + final_url)
                # Fetch directly from the internet (NO AUTH needed for TMDB)
                art_res = http.get(url = final_url)
            else:
                # OPTION B: It's a local file on the Kodi drive
                # Strip the image:// protocol
                if target.startswith("image://"):
                    target = target[8:]
                if target.endswith("/"):
                    target = target[:-1]
                
                # Use the Kodi Image Proxy
                b64_path = base64.encode(target)
                proxy_url = "http://%s/image/%s" % (KODI_IP, b64_path)
                print("Fetching Local Art via Proxy...")
                art_res = http.get(url=proxy_url, headers={"Authorization": AUTH})

            if art_res.status_code == 200:
                art_data = art_res.body()

    # Fallback to default Kodi logo if no art found or Kodi is off
    if not art_data:
        print("Using Default Art")
        art_data = http.get(DEFAULT_ART).body()

    return render.Root(
        child = render.Column(
            children = [
                # Scrolling Text for Show/Movie Title
                render.Box(
                    width = 64, height = 10,
                    child = render.Marquee(width = 64, child = render.Text(title_text, font="5x8"))
                ),
                # The Artwork Image
                render.Image(src = art_data, width = 64, height = 22),
            ],
        ),
    )