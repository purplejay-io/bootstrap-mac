import subprocess
import re
import json

def check_schedule(output: str) -> dict:
    pattern = r'(?P<event_type>wake|wakepoweron|poweron|sleep|shutdown) at (?P<time>\d{1,2}:\d{2}[AP]M) (?P<repeat>every day|Some days)'
    match = re.match(pattern, output)
    scheduled_event = {}
    if match:
        event_type = match.group("event_type")
        time = match.group("time")
        repeat = match.group("repeat")
        scheduled_event = {
            "event_type": event_type,
            "time": time,
            "repeat": repeat
        }

    return scheduled_event


pmset_settings = subprocess.check_output("pmset -g custom", shell=True, text=True)
pmset_schedule = subprocess.check_output("pmset -g sched", shell=True, text=True)

setting_profiles = ['AC Power', 'Battery Power']
schedule_profile = "Repeating power events"
settings = {}
current_profile = None

for line in pmset_settings.split('\n'):
    line = line.strip().strip(":")
    if line in setting_profiles:
        current_profile = line
        settings[current_profile] = {}
    elif current_profile and re.match(r'\w+\s+\d+', line):
        key, value = line.split()
        settings[current_profile][key] = int(value)

for line in pmset_schedule.split('\n'):
    line = line.strip().strip(":")
    if line == "Scheduled power events":
        break
    elif line in schedule_profile:
        current_profile = line
        settings[current_profile] = []
    elif current_profile:
        scheduled_event: dict = check_schedule(line)
        if scheduled_event:
            settings[current_profile].append(scheduled_event)

json_output = json.dumps(settings, indent=2)
print(json_output)
