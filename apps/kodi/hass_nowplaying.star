load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

def GetImage(URL):
  return http.get(URL)
  

def main(config):
  
  artUrl = config.get("ArtUrl")
  show = config.get("NowPlaying")
  print ("Starlark recvd artUrl: "+artUrl)
  print ("Starlark recvd show: "+show)
  
  art = GetImage(artUrl).body()
 
  
  return render.Root(
		show_full_animation = True,
		child=render.Column(
			children=[
				render.Marquee(
					width=64,
					child=render.Text(show),
					offset_start=64,
					offset_end=64,
					scroll_direction = "horizontal",
				),				
				render.Image(
					src = art,
					width = 64,
					height = 32-8,
				),
			],
		),
     )          
	
  	
    
  