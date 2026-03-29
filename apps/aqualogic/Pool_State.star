load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

imgPool_Heated = base64.decode("""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""")
imgPool = base64.decode("""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""")


def get_pump_status():
    PumpStatus = http.get("http://192.168.1.160:8111/api/v1/entity/hass>sensor_pool_operating_mode/attribute/string_sensor.value")
    FilterStatus = http.get("http://192.168.1.160:8111/api/v1/entity/hass>switch_pool_filter/attribute/power_switch.state")

    # body() returns the string; THEN we can replace/strip/upper
    mode = PumpStatus.body().replace('"', '').strip().upper()
    is_on = FilterStatus.body().replace('"', '').strip().upper()

    if is_on not in ["TRUE", "ON"]:
        return "Off"

    if mode == "SPA":
        return "Spa"
    if mode in ["POOL", "SPILLOVER"]:
        return "Pool"

    return "Off"

def HeaterStatus():
    resp = http.get("http://192.168.1.160:8111/api/v1/entity/hass%3Eswitch_pool_heater_actuator/attribute/power_switch.state")
    raw = resp.body().replace('"', '').strip().upper()

    if raw in ["TRUE", "ON"]:
        return "On"
    return "Off"
  
def CurrentTemp():
    url = "http://192.168.1.160:8111/api/v1/entity/hass>sensor_pool_water_temperature/attribute/string_sensor.value"
    if get_pump_status() == "Pool":
        url = "http://192.168.1.160:8111/api/v1/entity/hass>sensor_pool_water_temperature/attribute/string_sensor.value"
    if get_pump_status() == "Spa":
        url = "http://192.168.1.160:8111/api/v1/entity/hass>sensor_spa_temperature/attribute/string_sensor.value"

    resp = http.get(url)
    Temp = resp.body().replace('"', '').strip()
    return Temp

def GetImage():
  if HeaterStatus() == "On":
	return imgPool_Heated
  else:
    return imgPool

def main():
  binImage = GetImage()

  return render.Root(
    child = render.Row(
      children = [
	    render.Column(
          children= [
	        render.Image(
		      src = binImage,
		      width = 32,
		      height = 32,
		    ),	
		  ],
		),
		render.Column(
		  children = [
		    render.Box(
		      width = 3
		    ),
		  ],
		),
		render.Column(
	      children = [
		    render.Row(
			  expanded=True,
              main_align="space_evenly",
              cross_align="center",
			  children = [
			    render.Text(
		          get_pump_status(),
				),
			  ],
			),
			render.Row(
			  expanded=True,
              main_align="space_evenly",
              cross_align="center",
			  children = [
			    render.Text(
		          "",
				),
              ],
            ),
            render.Row(
			  expanded=True,
              main_align="space_evenly",
              cross_align="center",
			  children = [
			    render.Text(
		          CurrentTemp(),
				),
              ],
            ),
          ],
		),
	  ],
    ),
  )
