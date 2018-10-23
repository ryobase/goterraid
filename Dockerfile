FROM golang:alpine

LABEL maintainer="Moss Pakhapoca"

ADD . /go/src/github.com/ryobase/goterraid
WORKDIR /go/src/github.com/ryobase/goterraid

RUN apk add --no-cache git make zip curl
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

VOLUME [ "/go/src/github.com/ryobase/goterraid" ]