#!/usr/bin/env python3
import random
from subprocess import run, CalledProcessError

try:
    output = run(['taoup'], encoding="utf8", capture_output=True, check=True)
except CalledProcessError as cpe:
    print(f"Call to taoup failed: {cpe}")

lines = [line for line in output.stdout.splitlines() if not line.startswith("--")]
count = len(lines)
choice = random.randint(1, count)
print(lines[choice])
