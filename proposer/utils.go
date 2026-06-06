package proposer

import (
	"errors"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// GenerateUUID Generates a UUID out of
// UNIX nanosecond timestamp
func GenerateUUID() string {
	return strconv.FormatInt(time.Now().UnixNano(), 10)
}

// GetPeerList Obtains Peer List
// From Environment Variable
func GetPeerList() []string {
	return strings.Split(os.Getenv("PEERS"), ",")
}

const peerPort = "8080"

// PeerURL builds an intra-cluster HTTP URL using the container name.
func PeerURL(peer string, path string) string {
	return "http://" + peer + ":" + peerPort + path
}

// SendRequest handles sending of an HTTP GET Request
func SendRequest(url string) (int, error) {
	if url == "" {
		return 0, errors.New("empty url provided")
	}

	client := http.Client{
		Timeout: time.Duration(10 * time.Second),
	}

	response, err := client.Get(url)
	if err != nil {
		return 0, err
	}

	return response.StatusCode, nil
}
