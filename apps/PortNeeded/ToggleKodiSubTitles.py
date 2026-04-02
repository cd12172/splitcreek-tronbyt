import requests
import json
import argparse

# Replace these values with your Kodi IP address and port

kodi_ip = "192.168.150.93"
kodi_port = "8080"
kodi_username = "kodi"
kodi_password = "k"


# Construct the Kodi JSON-RPC URL
kodi_url = f"http://{kodi_ip}:{kodi_port}/jsonrpc"

def get_subtitle_streams():
    # Define the JSON-RPC payload to get the current player's subtitle properties
    payload = {
        "jsonrpc": "2.0",
        "method": "Player.GetProperties",
        "params": {
            "playerid": 1,  # 1 corresponds to the video player
            "properties": ["currentsubtitle", "subtitles"],
        },
        "id": 1,
    }

	# Add authentication if required		
    auth = None
    if kodi_username and kodi_password:
        auth = (kodi_username, kodi_password)

    # Send the request to Kodi
    response = requests.post(kodi_url, json=payload, auth=auth)
    result = response.json()

    # Check if the request was successful
    if "result" in result:
        current_subtitle = result["result"]["currentsubtitle"]
        subtitles = result["result"]["subtitles"]

        return current_subtitle, subtitles
    else:
        print("Failed to retrieve subtitle streams.")
        return None, None

def find_subtitle_by_substring(substring):
    _, subtitles = get_subtitle_streams()

    if subtitles:
        matching_subtitles = [subtitle for subtitle in subtitles if substring.lower() in subtitle["name"].lower()]
        return matching_subtitles
    else:
        return None

def disable_subtitles():
    # Define the JSON-RPC payload to disable subtitles
    payload = {
        "jsonrpc": "2.0",
        "method": "Player.SetSubtitle",
        "params": {
            "playerid": 1,  # 1 corresponds to the video player
            "subtitle": "off",  # "off" disables subtitles
			"enable": False,
        },
        "id": 1,
    }

	# Add authentication if required		
    auth = None
    if kodi_username and kodi_password:
        auth = (kodi_username, kodi_password)

    # Send the request to Kodi
    response = requests.post(kodi_url, json=payload, auth=auth)
    result = response.json()

    # Check if the request was successful
    if "result" in result and result["result"] == "OK":
        print("Successfully disabled subtitles.")
    else:
        print("Failed to disable subtitles.")



def enable_subtitle_by_index(index):
    # Define the JSON-RPC payload to set the subtitle by index
    payload = {
        "jsonrpc": "2.0",
        "method": "Player.SetSubtitle",
        "params": {
            "playerid": 1,  # 1 corresponds to the video player
            "subtitle": index,
			"enable": True
        },
        "id": 1,
    }

	# Add authentication if required		
    auth = None
    if kodi_username and kodi_password:
        auth = (kodi_username, kodi_password)

    # Send the request to Kodi
    response = requests.post(kodi_url, json=payload, auth=auth)
    result = response.json()

    # Check if the request was successful
    if "result" in result and result["result"] == "OK":
        print(f"Successfully enabled subtitle with index {index}.")
    else:
        print(f"Failed to enable subtitle with index {index}.")

def enable_subtitles_containing(substring="eng"):
    matching_subtitles = find_subtitle_by_substring(substring)

    if matching_subtitles:
        first_matching_subtitle = matching_subtitles[0]
        enable_subtitle_by_index(first_matching_subtitle["index"])
        print(f"Enabled subtitle containing '{substring}'.")
    else:
        print(f"No subtitles containing '{substring}' found.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Enable subtitles in Kodi.")
    parser.add_argument("subtitle_status", type=str, help="Substring to search for in subtitles.")

    args = parser.parse_args()

if args.subtitle_status.lower() == "on":
    enable_subtitles_containing("eng")
else:
    disable_subtitles()
    print(f"Subtitles off")