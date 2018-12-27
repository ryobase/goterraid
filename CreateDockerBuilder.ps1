Param(
    [string] $Tag = "1.0",
    [string] $Name = "gobuilder"
)

# Create and update Docker image
docker.exe build --rm -t ${Name}:${Tag} .