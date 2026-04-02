load("http.star", "http")
load("render.star", "render")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

# --- CONFIG ---
KODI_IP = "192.168.150.194:8080"
KODI_URL = "http://%s/jsonrpc" % KODI_IP
AUTH = "Basic a29kaTpr" 
DEFAULT_ART = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

def main(config):
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

    title_text = "Kodi Active"
    art_data = None

    if res.status_code == 200:
        item = res.json().get("result", {}).get("item", {})
        st = item.get("showtitle", "")
        ti = item.get("title", "")
        title_text = "%s: %s" % (st, ti) if st else (ti or "Playing")

        art_map = item.get("art", {})
        
        # Check these keys in order of "Best Look" for the display
        priorities = ["clearlogo", "banner", "poster", "thumb", "thumbnail", "fanart"]
        raw_url = ""
        for key in priorities:
            if art_map.get(key):
                raw_url = art_map[key]
                print("Selected Art Type: " + key) # This helps you see what it found
                break

        if raw_url:
            target = raw_url
            if target.startswith("image://"):
                target = target[8:] # Strip image://
            if target.endswith("/"):
                target = target[:-1] # Strip trailing slash
            
            # Use the Kodi proxy
            b64_path = base64.encode(target)
            proxy_url = "http://%s/image/%s" % (KODI_IP, b64_path)
            
            art_res = http.get(url=proxy_url, headers={"Authorization": AUTH})
            if art_res.status_code == 200:
                art_data = art_res.body()

    if not art_data:
        art_data = http.get(DEFAULT_ART).body()

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64, height = 10,
                    child = render.Marquee(width = 64, child = render.Text(title_text, font="5x8"))
                ),
                # If using a Poster, it will scale to fit the 64x22 area
                render.Image(src = art_data, width = 64, height = 22),
            ],
        ),
    )