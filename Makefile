GO           := go
PROMU        := $(GOPATH)/bin/promu
GOMETALINTER := $(GOPATH)/bin/gometalinter.v1
GO_BINDATA   := $(GOPATH)/bin/go-bindata
PREFIX       ?= $(shell pwd)
BIN_DIR      ?= $(PREFIX)/.build
TARBALL_DIR  ?= $(PREFIX)/.tarball
PACKAGE_DIR  ?= $(PREFIX)/.package
COVERAGEFILE ?= $(TMPDIR)/coverage.out
ARCH         ?= amd64
VERSION      ?= $(shell cat VERSION)

pkgs = $(shell go list ./... | grep -v /vendor/ | grep -v /test/)

DOCKER_IMAGE_NAME ?= puppetsync
DOCKER_IMAGE_TAG  ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))

all: format style vet test build

go-bindata:
	@echo ">> fetching go-bindata"
	@GOOS="$(shell uname -s | tr A-Z a-z)" \
	GOARCH="$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m)))" \
	$(GO) get -u github.com/jteeuwen/go-bindata/...

bindata: go-bindata
	cd $(PREFIX)
	$(GO_BINDATA) -pkg data -prefix ./ -o $(PREFIX)/data/bindata.go $(PREFIX)/data/...

build: promu bindata
	@mkdir -p $(PREFIX)/.build
	@$(PROMU) build --prefix $(BIN_DIR)

.PHONY: benchmark
benchmark: generate
	@$(GO) test -bench=. $(pkgs)

.PHONY: clean
clean:
	rm -rf $(PACKAGE_DIR) $(BIN_DIR)
	rm -rf *.log integration/logs/*.log

checksum:
	@$(PROMU) checksum $(BIN_DIR)

crossbuild: promu
	@$(PROMU) crossbuild

docker:
	@echo ">> building docker image"
	@docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" .

format:
	go fmt $(pkgs)

.PHONY: generate
generate:
	@$(GO) generate $(pkgs)

.PHONY: gometalinter
gometalinter:
	@echo ">> fetching gometalinter"
	@GOOS="$(shell uname -s | tr A-Z a-z)" \
	GOARCH="$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m)))" \
	$(GO) get -u gopkg.in/alecthomas/gometalinter.v1
	@echo ">> fetching gometalinter dependencies"
	@$(GOMETALINTER) --install

.PHONY: lint
lint: gometalinter
	$(GOMETALINTER) --vendor --disable=errcheck

promu:
	@echo ">> fetching promu"
	@GOOS="$(shell uname -s | tr A-Z a-z)" \
	GOARCH="$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m)))" \
	$(GO) get -u github.com/prometheus/promu

.PHONY: shared
shared: generate
	@$(GO) install -buildmode=shared -linkshared $(pkgs)

style:
	@echo ">> checking code style"
	@! gofmt -d $(shell find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'

tarball: promu
	@echo ">> building release tarball"
	@$(PROMU) tarball --prefix $(TARBALL_DIR) $(BIN_DIR)

test:
	@$(GO) test $(pkgs)

test-short:
	@echo ">> running short tests"
	@$(GO) test -short $(pkgs)

.PHONY: test-integration
test-integration: build
	@export PREFIX=$(PREFIX)
	@$(BATS) integration/
	@export PREFIX

.PHONY: test-unit
test-unit:
	@$(GO) test -cover $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

.PHONY: all build clean crossbuild docker format promu style tarball test vet
