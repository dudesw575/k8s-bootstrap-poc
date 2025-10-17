#!/bin/bash
echo "Generating traffic for Kiali visualization..."
echo "Press Ctrl+C to stop"

while true; do
    curl -s http://hello.localhost > /dev/null && echo "✓ hello.localhost"
    curl -s -H "version: v2" http://hello.localhost > /dev/null && echo "✓ hello.localhost (v2)"
    sleep 2
done