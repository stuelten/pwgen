BIN=pwgen-go
LDFLAGS=-s -w
.PHONY: build clean test
build:
	GOFLAGS='' CGO_ENABLED=0 go build -trimpath -ldflags "$(LDFLAGS)" -o $(BIN)
test:
	go test ./...
clean:
	rm -f $(BIN)
