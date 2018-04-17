import re
import sys
import math

if len(sys.argv) < 2:
    print("ERROR: usage: python3 program.py file")
    exit(1)
i = 0
minutes = 0
seconds = 0
pattern = re.compile(r'(?P<minutes>\d+):(?P<seconds>\d+)') # any minutes:seconds regex
with open(sys.argv[1], 'r') as f:
    for line in f.readlines():
        result = pattern.search(line)
        if(result != None):
            minutes += int(result.group('minutes'))
            seconds += int(result.group('seconds'))
        i +=  1

print("timeleft: {}:{}:{}".format(math.floor((minutes + seconds / 60.0) / 60.0), \
                                  (minutes % 60) + math.floor(seconds / 60.0), \
                                  seconds % 60))
