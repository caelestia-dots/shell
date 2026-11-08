#!/usr/bin/python3
"""Watch joystick input without grabbing it; ignore initial state and stick drift."""
import glob
import os
import select
import struct
import time

fds = {}
axes = {}
last_emit = 0
while True:
    paths = set(glob.glob('/dev/input/js*'))
    for fd, path in list(fds.items()):
        if path not in paths:
            os.close(fd)
            del fds[fd]
            axes.pop(fd, None)
    for path in paths - set(fds.values()):
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            fds[fd] = path
            axes[fd] = {}
        except OSError:
            pass
    ready = select.select(list(fds), [], [], 1)[0] if fds else []
    if not fds:
        time.sleep(1)
    for fd in ready:
        try:
            data = os.read(fd, 8 * 64)
            if not data:
                raise OSError('disconnected')
            active = False
            for _, value, kind, number in struct.iter_unpack('IhBB', data):
                if kind & 0x80:
                    if kind & 2:
                        axes[fd][number] = value
                    continue
                if kind == 1:
                    active = True
                elif kind == 2:
                    previous = axes[fd].get(number, value)
                    if abs(value - previous) >= 4000:
                        active = True
                        axes[fd][number] = value
            now = time.monotonic()
            if active and now - last_emit >= 0.5:
                print('activity', flush=True)
                last_emit = now
        except OSError:
            os.close(fd)
            del fds[fd]
            axes.pop(fd, None)
