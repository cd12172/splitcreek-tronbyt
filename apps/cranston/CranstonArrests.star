"""
Cranston Arrests: one recent Cranston RI PD arrest per rotation on the Tronbyt.

Data: cranston-arrests service on Debian (http://192.168.1.160:8131), which polls the
Cranston PD "Arrest Logs" post every 15 min and keeps time, name, age, charges, street
and arrest number (no house numbers). The list is cached 15 min here; /next is
called uncached each render to advance the cursor, so each rotation shows the next
arrest. If /next fails, the index comes from the clock (changes every minute).

Layout (64x32, tom-thumb, 5 lines x 6 px): CRANSTON + date / name + age (marquee) /
charge (marquee) / street (marquee) / time + arrest no. Date and time don't both fit on line 1 at 64 px, so time is on line 4.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

BASE = "http://192.168.1.160:8131"
RED = "#ff3b30"
GREY = "#9a9a9a"
GREEN = "#34c759"
AMBER = "#ffb000"
BLUE = "#4da3ff"
FONT = "tom-thumb"

def text(s, color = "#ffffff"):
    return render.Text(s, font = FONT, color = color)

def line(s, color):
    # 4 px per tom-thumb glyph; scroll only when it doesn't fit
    if len(s) * 4 <= 65:
        return text(s, color)
    return render.Marquee(width = 64, child = text(s, color), offset_start = 8, offset_end = 8)

def get_json(url, ttl):
    resp = http.get(url, ttl_seconds = ttl)
    if resp.status_code != 200:
        return None
    return json.decode(resp.body())

def main(config):
    data = get_json(BASE + "/arrests.json", 900)
    if data == None:
        return []
    entries = data.get("entries", [])
    if len(entries) == 0:
        return render.Root(child = render.Box(child = render.Column(
            cross_align = "center",
            children = [text("CRANSTON", RED), text("no recent", GREY), text("arrests", GREY)],
        )))

    if config.get("index"):
        idx = int(config.get("index"))
    else:
        # unique query string defeats pixlet's http cache so the cursor really advances
        nxt = get_json(BASE + "/next?t=%d" % time.now().unix, 1)
        idx = int(nxt["index"]) if nxt and nxt.get("index") != None else time.now().unix // 60
    e = entries[idx % len(entries)]
    charges = e.get("charges", "") or "Arrest"
    if len(charges) > 72:
        charges = charges[:69] + "..."

    when = e.get("when", "")            # "11/3 9:15P"
    parts = when.split(" ")
    date = parts[0] if len(parts) > 0 else ""
    clock = parts[1] if len(parts) > 1 else ""
    name = e.get("name", "")
    if name and e.get("age"):
        name = "%s, %s" % (name, e["age"])
    num = e.get("arrest_no", "").replace("-AR", "")
    num = "#" + num.split("-")[-1] if num else ""

    return render.Root(
        delay = 50,
        show_full_animation = True,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Row(expanded = True, main_align = "space_between", children = [
                    text("CRANSTON", RED),
                    text(date, GREY),
                ]),
                line(name or "-", GREEN),
                line(charges, "#ffffff"),
                line(e.get("street", "") or "Cranston", AMBER),
                render.Row(expanded = True, main_align = "space_between", children = [
                    text(clock, BLUE),
                    text(num, GREY),
                ]),
            ],
        ),
    )
