# Justfile for loteria

# Check app status
status:
    fly status --app loteria

# Start the machine (wake it up from stopped state)
start:
    fly machine start --app loteria

# SSH into the running Fly.io instance with IEx
ssh:
    fly ssh console --app loteria -C "/app/bin/loteria remote"

# Start the machine and then SSH into it
connect: start
    @sleep 5
    fly ssh console --app loteria -C "/app/bin/loteria remote"
