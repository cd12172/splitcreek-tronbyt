"""
PrintStatus: FlashForge Adventurer 5M Pro print on the Tronbyt.

Shows the current file's thumbnail, progress and ETA while printing, then DONE until
the plate is cleared. Reactor (rule "Printer on Tronbyt") adds/removes this app from
the rotation; this app only draws. Data comes from Reactor's HTTP API (same as
apps/aqualogic/Pool_State.star); the thumbnail comes from HA's image proxy using the
image entity's rotating access token, so no HA token is stored here.

Config: demo=1 renders sample values (for previews without a print).
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

REACTOR = "http://192.168.1.160:8111/api/v1/entity/hass>"
HA = "http://192.168.1.112:8123"
PRINTER = "snmomd9b00646"
TZ = "America/New_York"

GREEN = "#2ecc40"
AMBER = "#ffb000"
GREY = "#888888"
BAR_BG = "#333333"
BAR_FG = "#0099ff"

def reactor(entity, attribute):
    resp = http.get(REACTOR + entity + "/attribute/" + attribute, ttl_seconds = 30)
    if resp.status_code != 200:
        return ""
    return resp.body().replace('"', "").strip()

def thumbnail():
    token = reactor("image_" + PRINTER + "_current_file_thumbnail", "x_hass_attr.access_token")
    if not token or token == "null":
        return None
    url = HA + "/api/image_proxy/image." + PRINTER + "_current_file_thumbnail?token=" + token
    resp = http.get(url, ttl_seconds = 300)
    if resp.status_code != 200:
        return None
    return resp.body()

def clock(iso):
    """'2026-10-10T19:42:00+00:00' -> '3:42p' local, or '' if not a time."""
    if not iso or iso in ("unavailable", "unknown", "null"):
        return ""
    t = time.parse_time(iso.replace(" ", "T")).in_location(TZ)
    return t.format("3:04PM").replace("AM", "a").replace("PM", "p")

def progress_bar(pct, width):
    filled = int(width * max(0, min(100, pct)) / 100)
    return render.Stack(children = [
        render.Box(width = width, height = 3, color = BAR_BG),
        render.Box(width = max(filled, 1), height = 3, color = BAR_FG),
    ])

def text(s, color = "#ffffff"):
    return render.Text(s, font = "tom-thumb", color = color)

def main(config):
    if config.get("demo") == "1":
        status, pct, eta, img = config.get("status", "printing"), 42, "4:15p", None
    else:
        status = reactor("sensor_" + PRINTER + "_machine_status", "string_sensor.value")
        raw = reactor("sensor_" + PRINTER + "_print_progress", "string_sensor.value")
        pct = int(float(raw)) if raw and raw.replace(".", "", 1).isdigit() else 0
        eta = clock(reactor("sensor_" + PRINTER + "_print_completion_time", "string_sensor.value"))
        img = thumbnail()

    if status == "completed":
        lines = [text("DONE", GREEN), text("Clear", GREY), text("plate", GREY)]
    elif status in ("paused", "pausing"):
        lines = [text("Paused", AMBER), text("%d%%" % pct), progress_bar(pct, 29)]
    elif status in ("heating", "calibrating"):
        lines = [text("Heating" if status == "heating" else "Calib", AMBER), text(eta, AMBER)]
    else:
        lines = [text("%d%%" % pct), progress_bar(pct, 29), text(eta, AMBER)]

    if img:
        left = render.Image(src = img, width = 32, height = 32)
    else:
        left = render.Box(width = 32, height = 32, color = "#202020", child = text("3D", GREY))

    return render.Root(
        child = render.Row(
            children = [
                left,
                render.Box(width = 2, height = 32),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    children = lines,
                ),
            ],
        ),
    )
