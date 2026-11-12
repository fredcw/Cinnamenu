#!/bin/bash

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    # We temporarily grant the local superuser (root) access to XWayland and revoke it immediately after the task is complete.
    xhost +si:localuser:root >/dev/null 2>&1
    pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$@"
    EXIT_CODE=$?
    xhost -si:localuser:root >/dev/null 2>&1
    exit $EXIT_CODE
else
    # Classic behavior for X11, unchanged
    pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "$@"
fi
