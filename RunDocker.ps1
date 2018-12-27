Param(
    [string] $Tag = "1.0",
    [string] $Name = "gobuilder"
)

docker.exe run --rm -it -v ${pwd}:/go/src/github.com/ryobase/goterraid ${Name}:${Tag}