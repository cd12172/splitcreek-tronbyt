load("http.star", "http")
load("render.star", "render")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

# --- SETTINGS ---
KODI_IP = "192.168.150.194:8080"
KODI_URL = "http://%s/jsonrpc" % KODI_IP
AUTH = "Basic a29kaTpr" 
DEFAULT_ART = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

# CHANGE THIS to "poster", "fanart", "banner", "clearlogo", or "thumbnail"
PREFER_ART = "fanart" 

def main(config):
    # 1. Fetch metadata and ALL art properties
    res = http.post(
        url = KODI_URL,
        headers = {"Authorization": AUTH},
        body = json.encode({
            "jsonrpc": "2.0",
            "method": "Player.GetItem",
            "params": {
                "properties": ["title", "showtitle", "art"], 
                "playerid": 1
            },
            "id": 1,
        }),
    )

    title_text = "Kodi Active"
    art_data = None

    if res.status_code == 200:
        result = res.json().get("result", {})
        item = result.get("item", {})
        
        # Text Logic
        st = item.get("showtitle", "")
        ti = item.get("title", "")
        title_text = "%s: %s" % (st, ti) if st else (ti or "Playing")

        # 2. Art Selection Logic
        art_map = item.get("art", {})
        
        # We try your preferred type first, then fall back through the others
        raw_url = art_map.get(PREFER_ART) or \
                  art_map.get("poster") or \
                  art_map.get("thumbnail") or \
                  art_map.get("fanart")

        if raw_url:
            # Handle Kodi's internal image:// protocol
            clean_url = raw_url
            if raw_url.startswith("image://"):
                clean_url = raw_url.replace("image://", "").removesuffix("/")
            
            # Re-encode for the Kodi Image Proxy
            proxy_url = "http://%s/image/%s" % (KODI_IP, base64.encode(clean_url))
            
            art_res = http.get(url=proxy_url, headers={"Authorization": AUTH})
            if art_res.status_code == 200:
                art_data = art_res.body()

    # Final Fallback if everything failed
    if not art_data:
        art_data = http.get(DEFAULT_ART).body()

    # 3. Render Layout
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 10,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(title_text, font="5x8", color="#fff"),
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 22,
                    child = render.Image(
                        src = art_data,
                        width = 64,
                        height = 22,
                    ),
                ),
            ],
        ),
    )