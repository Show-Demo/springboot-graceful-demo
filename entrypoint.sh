#!/bin/sh
set -eu

# Use exec so Java becomes tini's direct child and receives signals correctly.
exec java -jar /app/app.jar
