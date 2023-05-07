import json
import sys
import subprocess
import re

def run_defaults_read(plist_path, key):
    cmd = ['defaults', 'read', plist_path, key]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()

def parse_defaults_output(defaults_output):
    # Remove curly braces
    stripped_output = re.sub(r'^\s*{', '', defaults_output)
    stripped_output = re.sub(r'}\s*$', '', stripped_output)

    lines = stripped_output.split('\n')
    parsed_data = {}

    for line in lines:
        if line:
            line.split()
            key, value = [part.strip() for part in line.split('=', 1)]
            key = key.strip('"')
            value = value.strip(';')

            try:
                parsed_value = json.loads(value)
            except json.JSONDecodeError:
                parsed_value = value.strip('"')

            parsed_data[key] = parsed_value

    return parsed_data

def main(plist_path, key):
    defaults_output = run_defaults_read(plist_path, key)
    parsed_data = parse_defaults_output(defaults_output)

    json_output = json.dumps(parsed_data, indent=2)
    print(json_output)

    # with open(json_output_path, 'w') as json_file:
    #     json.dump(parsed_data, json_file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    plist_path = sys.argv[1]
    key = sys.argv[2]
    # json_output_path = sys.argv[3]

    main(plist_path, key)

# Example
# python3 tools/defaults_plist2json.py /Library/Preferences/com.apple.PowerManagement.DD36C36D-C9BE-5E26-BC44-F9399FE3928B.plist "AC Power" output.json