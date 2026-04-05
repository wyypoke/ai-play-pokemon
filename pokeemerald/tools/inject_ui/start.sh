#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Pokemon Team Injector..."
echo "Open http://localhost:8080 in your browser"
echo ""
python3 -m http.server 8080
