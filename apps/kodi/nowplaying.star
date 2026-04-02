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
    # 1. Ask Kodi for current item
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
        
        # Build Title
        st = item.get("showtitle", "")
        ti = item.get("title", "")
        title_text = "%s: %s" % (st, ti) if st else (ti or "Playing")

        # 2. Advanced Art Selection
        art_map = item.get("art", {})
        
        # Priority list: we check these keys in order until we find one
        # 'thumb' is often the most reliable for whatever is currently playing
        priorities = ["clearlogo", "poster", "thumb", "thumbnail", "fanart"]
        raw_url = ""
        for key in priorities:
            if art_map.get(key):
                raw_url = art_map[key]
                break

        if raw_url:
            # KODI IMAGE PROXY LOGIC:
            # We need to take the raw URL, strip 'image://', 
            # and URL-unquote it if it's already encoded.
            # However, in Starlark, the simplest path is:
            target = raw_url
            if target.startswith("image://"):
                # Remove "image://" prefix
                target = target[8:]
            if target.endswith("/"):
                # Remove trailing slash
                target = target[:-1]
            
            # Kodi expects the internal path to be Base64 encoded
            b64_path = base64.encode(target)
            proxy_url = "http://%s/image/%s" % (KODI_IP, b64_path)
            
            print("Fetching Art from: " + proxy_url) # Check your terminal logs!
            
            art_res = http.get(url=proxy_url, headers={"Authorization": AUTH})
            if art_res.status_code == 200:
                art_data = art_res.body()
            else:
                print("Art Fetch Failed: Status %d" % art_res.status_code)

    # Final Fallback
    if not art_data:
        art_data = http.get(DEFAULT_ART).body()

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64, height = 10,
                    child = render.Marquee(width = 64, child = render.Text(title_text, font="5x8"))
                ),
                render.Image(src = art_data, width = 64, height = 22),
            ],
        ),
    )