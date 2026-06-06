
CONTAINER_RUNTIME ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

build:
	@echo "Building Paxos Server"	
	go build -o paxos/paxos main.go

test:
	@echo "Testing GoPaxos"	
	go test -v --cover ./...

provision:
	@echo "Provisioning Paxos Cluster"	
	CONTAINER_RUNTIME=$(CONTAINER_RUNTIME) bash scripts/provision.sh

paxos-build:
	@echo "Building Paxos container image"	
	$(CONTAINER_RUNTIME) build -t paxos -f Dockerfile .

paxos-run:
	@echo "Running single Paxos container"
	$(CONTAINER_RUNTIME) run -p 8080:8080 -d paxos

info:
	echo "Paxos Cluster Nodes"
	$(CONTAINER_RUNTIME) ps | grep 'paxos'
	$(CONTAINER_RUNTIME) network ls | grep paxos_network

clean:
	@echo "Cleaning Paxos Cluster"
	$(CONTAINER_RUNTIME) ps -a | awk '$$2 ~ /paxos/ {print $$1}' | xargs -I {} $(CONTAINER_RUNTIME) rm -f {}
	$(CONTAINER_RUNTIME) network rm paxos_network 2>/dev/null || true
