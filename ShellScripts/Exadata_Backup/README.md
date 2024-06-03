# Exadata Backup Files

# This script will invoke IBM Rman Backup scripts on remote Exadata nodes
# It is meant to execute backups even if the local RAC instance is down, by redirecting its execution
# to a remote node using # Exadata DCLI tool