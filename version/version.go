package version

import (
	"fmt"
	"runtime"
)

// GitCommit shows git commit that was compiled. This will be filled in by the compiler.
var GitCommit string

// Version shows main version number that is being run at the moment.
const Version = "0.1.0"

// BuildDate shows the sucessfully built date.
var BuildDate = "2018-10-22"

// GoVersion shows the currently installed Go version.
var GoVersion = runtime.Version()

// OsArch shows the build platform
var OsArch = fmt.Sprintf("%s %s", runtime.GOOS, runtime.GOARCH)
