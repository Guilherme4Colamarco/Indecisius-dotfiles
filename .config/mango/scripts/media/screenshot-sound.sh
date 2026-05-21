#!/bin/bash
# Play the GNOME-style screenshot/camera shutter sound without blocking the caller.

if command -v canberra-gtk-play >/dev/null 2>&1; then
	canberra-gtk-play -i camera-shutter -d "screenshot" >/dev/null 2>&1 &
elif command -v pw-play >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/camera-shutter.oga ]; then
	pw-play /usr/share/sounds/freedesktop/stereo/camera-shutter.oga >/dev/null 2>&1 &
elif command -v paplay >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/camera-shutter.oga ]; then
	paplay /usr/share/sounds/freedesktop/stereo/camera-shutter.oga >/dev/null 2>&1 &
fi
