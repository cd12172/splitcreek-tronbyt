load("http.star", "http")
load("render.star", "render")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

# --- SETTINGS ---
KODI_IP = "192.168.150.194:8080"
KODI_URL = "http://%s/jsonrpc" % KODI_IP
# Base64 for 'kodi:k'
AUTH = "Basic a29kaTpr" 
DEFAULT_ART = "https://kodi.wiki/images/1/10/Thumbnail-dark.png"

def main(config):
    # 1. Fetch metadata
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

        # 2. Handle Artwork
        art_map = item.get("art", {})
        # Prefer Clearlogo for a clean "Now Playing" look, fallback to Thumbnail
        raw_url = art_map.get("clearlogo") or art_map.get("thumbnail")

        if raw_url and raw_url.startswith("image://"):
            # Clean and encode for Kodi's image proxy
            clean = raw_url.replace("image://", "").removesuffix("/")
            final_url = "http://%s/image/%s" % (KODI_IP, base64.encode(clean))
            
            art_res = http.get(url=final_url, headers={"Authorization": AUTH})
            if art_res.status_code == 200:
                art_data = art_res.body()

    # Fallback image if Kodi has no art or fetch failed
    if not art_data:
        art_data = http.get(DEFAULT_ART).body()

    # 3. Render Layout
    return render.Root(
        child = render.Column(
            children = [
                # Top Marquee (8px height)
                render.Box(
                    width = 64,
                    height = 10,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(title_text, font="5x8", color="#fff"),
                    ),
                ),
                # Artwork (22px height)
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