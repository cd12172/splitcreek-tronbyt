import subprocess
import re
import argparse

def get_currently_playing_program_id(tivo_ip, tivo_port):
    command = ["telnet", tivo_ip, tivo_port, "NowPlaying"]
    print(" ".join(command))  # Print the telnet command
    result = subprocess.run(command, stdout=subprocess.PIPE, text=True)

    # Extract the ProgramID of the currently playing show
    match = re.search(r'ProgramID:\s*(\d+)', result.stdout)

    if match:
        program_id = match.group(1)
        return program_id
    else:
        return None

def get_artwork_uri(tivo_ip, tivo_port, program_id):
    command = ["telnet", tivo_ip, tivo_port, f"getDetails {program_id}"]
    print(" ".join(command))  # Print the telnet command
    result = subprocess.run(command, stdout=subprocess.PIPE, text=True, shell=True)

    # Extract the SeriesPosterUrl using regular expression
    match = re.search(r'SeriesPosterUrl:\s*(.*)', result.stdout)
    
    if match:
        artwork_uri = match.group(1)
        return artwork_uri
    else:
        return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Retrieve Now Playing information and artwork URI from a TiVo.")
    parser.add_argument("tivo_ip", help="TiVo IP address")
    parser.add_argument("--tivo_port", default="31339", help="TiVo port (default is 31339)")

    args = parser.parse_args()

    # Get the ProgramID of the currently playing show
    current_program_id = get_currently_playing_program_id(args.tivo_ip, args.tivo_port)

    if current_program_id:
        print(f"Currently Playing ProgramID: {current_program_id}")

        # Get the artwork URI for the currently playing show
        artwork_uri = get_artwork_uri(args.tivo_ip, args.tivo_port, current_program_id)

        if artwork_uri:
            print(f"Artwork URI: {artwork_uri}")
        else:
            print("Unable to retrieve artwork URI.")
    else:
        print("No currently playing show.")
