#!/bin/bash
echo "$(date): Starting start-import-process.sh" >> /tmp/startup-debug.log
/opt/keycloak/custom-scripts/import.sh >> /tmp/startup-debug.log 2>&1 & disown
echo "$(date): Started import.sh in background" >> /tmp/startup-debug.log