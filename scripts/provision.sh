#!/bin/bash

if [[ -n "${CONTAINER_RUNTIME:-}" ]]; then
    runtime="$CONTAINER_RUNTIME"
elif command -v podman >/dev/null 2>&1; then
    runtime="podman"
elif command -v docker >/dev/null 2>&1; then
    runtime="docker"
else
    echo "Error: neither podman nor docker found in PATH"
    echo "Install one of them or set CONTAINER_RUNTIME=docker|podman"
    exit 255
fi

echo "Using container runtime: $runtime"

# Initialize ENV Variables peers
# A list of all the ports
# of the paxos peers
declare -a peers=()
declare -a peer_id_list=()

# Name of the Paxos cluster network
# connecting the peers
network="paxos_network"

# number of peers to be provisioned
# Default 3 peers are provisioned
peers_count=$1

# Err check number of peers
# If no peers count is given defaul to 3
if [[ $peers_count -eq "" ]]; then
    peers_count=3
fi

echo "Number of peers: $peers_count"

# Exit when there are less than 3 peers
if [[ $peers_count -le 2 ]]; then
    echo "Number of peers cannot be less than 3"
    exit 255
fi

# Exit when there are more than 1000 peers
if [[ $peers_count -ge 1000 ]]; then
    echo "Number of peers cannot be more than 1000"
    exit 255
fi

# Exit when there are an even
# number of peers provided
if [[ $(($peers_count % 2)) -eq 0 ]]; then
    echo "Number of peers cannot be an even value"
    exit 255
fi

# Check if port is available and then
# append to peers starting from 8000
available_port=8000
provisioned_ports_count=0

echo "Cleaning previous stale peers"
$runtime ps -a | awk '$2 ~ /paxos/ {print $1}' | xargs -I {} $runtime rm -f {}
$runtime network rm "$network" 2>/dev/null || true

echo "Reserving ports for peers"

for port in {8000..9000}; do
    if [[ provisioned_ports_count -eq peers_count ]]; then
        break
    fi

    netstat -an | grep $port
    if [[ $? -ne 0 ]]; then
        peers+=($port)
        ((provisioned_ports_count++))
    fi
done

if [[ provisioned_ports_count -ne peers_count ]]; then
    echo "Unable to reserve ports for peers"
    exit 255
fi

echo "Reserved ports:" ${peers[*]}
comma_separated_peers=$(
    IFS=,
    echo "${peers[*]}"
)

# Create peers from peer list
# and pass PORT = peers[[i]]
echo "Provisioning Paxos Cluster"

echo "Building Paxos container image"
$runtime build -t paxos -f Dockerfile .

if [[ $? -ne 0 ]]; then
    echo "Unable to build Paxos container image"
    exit 255
fi

echo "Building Paxos cluster network"
$runtime network create "$network"

for ((id = 0; id < $peers_count; ++id)); do
    peer_id_list+=(peer-$id)
done

comma_separated_peer_id_list=$(
    IFS=,
    echo "${peer_id_list[*]}"
)

for peer_index in "${!peers[@]}"; do
    $runtime run -p "${peers[$peer_index]}":8080 --network "$network" -e "PEERS="$comma_separated_peer_id_list"" -e "NETWORK="$network"" --name="peer-$peer_index" -d paxos
done

echo "Paxos Cluster Nodes"
$runtime ps | grep 'paxos'
$runtime network ls | grep "$network"
