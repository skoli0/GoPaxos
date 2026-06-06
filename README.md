# GoPaxos

Paxos Made Simple, Implemented On Docker or Podman Containers

## Introduction

Paxos is a consensus algorithm used to establish consensus among several nodes in a distributed system. Here, we use containers to run each Paxos cluster node, and Golang to implement the Paxos made simple protocol among every node. Using Paxos the cluster forms a very simple distributed Key-Value Store enabling the user to write and read data across any node in the cluster.

## Container Runtime

GoPaxos supports [Docker](https://www.docker.com/) and [Podman](https://podman.io/). The Makefile and `scripts/provision.sh` auto-detect whichever runtime is available — **Podman is preferred when both are installed**.

Force a specific runtime by passing `CONTAINER_RUNTIME` to any `make` target, or export it for the session:

```bash
make provision CONTAINER_RUNTIME=docker
make info CONTAINER_RUNTIME=podman

export CONTAINER_RUNTIME=docker
make provision
make clean
```

When provisioning, the script prints which runtime it selected (e.g. `Using container runtime: podman`).

## Prerequisites (macOS)

You need either Docker or Podman installed and running before provisioning the cluster.

### Option A: Docker Desktop

1. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
2. Start Docker Desktop and wait until it reports the engine is running.
3. Verify:

```bash
docker info
```

### Option B: Podman

On macOS, Podman runs containers inside a lightweight Linux VM called a Podman machine.

1. Download the installer from [podman.io](https://podman.io/docs/installation), or install via Homebrew:

```bash
brew install podman
```

2. Create and start the default VM (required before any `podman` or `make` commands):

```bash
podman machine init --now
```

If you already initialized a machine, start it with:

```bash
podman machine start
```

3. Verify Podman is ready:

```bash
podman info
```

If you see connection errors, restart the machine:

```bash
podman machine stop
podman machine start
```

## Steps

After cloning the repo, provision the cluster:

```bash
make provision
```

This creates a 3-node Paxos cluster on its own container network (`paxos_network`). Peer ports are assigned starting at 8000.

To provision a different number of peers (must be an odd value ≥ 3):

```bash
bash scripts/provision.sh 5
```

View the status of the cluster:

```bash
make info
```

Send Set and Get requests to any peer node using its allocated port:

```bash
curl -i http://localhost:<peer-port>/store/set/<key>/<value>
curl -i http://localhost:<peer-port>/store/get/<key>
```

View Paxos transaction logs for a peer (use `docker` or `podman` depending on your runtime):

```bash
docker logs peer-0
# or
podman logs peer-0
```

To tear down the cluster:

```bash
make clean
```

If the image remains after cleanup, remove it manually:

```bash
docker rmi paxos
# or
podman rmi paxos
```

## Make Targets

| Target        | Description                                      |
|---------------|--------------------------------------------------|
| `make provision`   | Build the image and start the Paxos cluster |
| `make info`        | List running peer containers and network    |
| `make clean`       | Remove peer containers and the cluster network |
| `make paxos-build` | Build the `paxos` container image only      |
| `make paxos-run`   | Run a single Paxos container on port 8080     |
| `make build`       | Build the Paxos server binary locally       |
| `make test`        | Run Go tests                                |

All container targets respect `CONTAINER_RUNTIME` (see [Container Runtime](#container-runtime)).

## Paxos

The Paxos consensus algorithm is implemented using Golang running as a Paxos server in each node. Paxos consists of 3 phases:

- **Prepare Phase**:  This is the start of the Paxos phase enabled when a client would like to write data to the cluster. Here, the Prepare process generates a round ID of its own and propagates it to all the nodes in the cluster. Once a majority of nodes accept the prepare message it then moves to the accept phase.


- **Accept Phase**:  Here the same leader node that transmitted the prepare message sends an accept request to all the nodes again to accept the given value to be chosen, thus achieving consensus among a majority of nodes and at times all the nodes.


- **Learn Phase**: Once the above two phases are complete the leader then sends a learn request which enables all the nodes to persist the agreed-upon value to its store.

## Containers

Each Paxos node runs in an isolated container. A shared network (`paxos_network`) connects all peers so they can communicate with each other and expose ports to the host.

- **Docker**: Start Docker Desktop before running `make provision`.
- **Podman (macOS)**: Ensure the Podman machine is running (`podman machine start`) before provisioning or interacting with the cluster.

## Simple Paxos vs Multi-Paxos

The current implementation of Paxos here is Paxos Made Simple protocol, which in a real-world production environment would fare much better. Future improvements to GoPaxos would look at upgrading the protocol to Multi-Paxos. Multi-Paxos works by running multiple Paxos rounds across the nodes, auto leader election, log replication to handle failure scenarios, and several other improvements.

## References

 - [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf) [Leslie Lamport]
 - [Paxos lecture (Raft user study)](https://youtu.be/JEpsBg0AO6o) [Diego Ongaro & John Ousterhout]
