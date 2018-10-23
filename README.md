GO Terra ID
===========

A simple AWS Lambda Go project that generate a random UUID each time a function is executed. This project uses API Gateway, Lambda, and DynamoDB. Terraform file is provided

## Getting started

This project requires Go, Terraform, and `dep` to be installed. On Mac OS with Homebrew you can just run `brew install go`.

Dockerfile is provided for building

```bash
docker build --rm -t gobuilder:1.0 -f ./Dockerfile .
docker run --rm -it -v ${pwd}:/go/src/github.com/ryobase/goterraid gobuilder:1.0
```

## Deployment using Terraform

Either run the handy ``make deploy`` or these commands to achieve the same effect:

```bash
terraform init
terraform get -update
terraform plan
terraform apply
```

### Testing

``make test``