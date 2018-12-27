.PHONY: build build-linux deploy teardown clean test help default

BIN_NAME=goterraid

VERSION := $(shell grep "const Version " version/version.go | sed -E 's/.*"(.+)"$$/\1/')
GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
BUILD_DATE=$(shell date '+%Y-%m-%d-%H:%M:%S')
DEPLOY_NAME := "function"

default: help

help:
	@echo 'Management commands for goterraid:'
	@echo
	@echo 'Usage:'
	@echo '    make build           Compile the project.'
	@echo '    make build-linux     Compile the project for Linux.'
	@echo '    make compress        Compress and package binary file.'
	@echo '    make get-deps        Runs dep ensure, mostly used for ci.'
	@echo '    make deploy          Use Terraform to deploy to AWS.'
	@echo '    make aws-ready       Build and create a deployable zip file. Ready for AWS deployment.'
	
	@echo '    make clean           Clean the directory tree.'
	@echo '    make teardown        Clean and destroy Terraform infrastructure.'
	@echo

build:
	@echo "building ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags "-X github.com/ryobase/goterraid/version.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X github.com/ryobase/goterraid/version.BuildDate=${BUILD_DATE}" -o bin/${BIN_NAME}

build-linux:
	@echo "building ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags "-w -s" -o bin/${BIN_NAME}

compress:
	mkdir -p deploy && zip -r ./deploy/${DEPLOY_NAME}.zip ./bin

aws-ready: build-linux compress

deploy: build-linux compress
	@echo "Deploying to AWS"
	@terraform init -input=false
	@terraform get -update
	@terraform plan -out=tfplan -input=false
	@terraform apply -input=false tfplan

get-deps:
	dep ensure

clean:
	@test ! -e bin/${BIN_NAME} || rm bin/${BIN_NAME}
	@test ! -e deploy/${DEPLOY_NAME}.zip || rm deploy/${DEPLOY_NAME}.zip

teardown: clean
	@terraform destroy

test:
	go test ./...

