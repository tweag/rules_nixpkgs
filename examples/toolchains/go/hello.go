package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Printf("Go version: %s\n", runtime.Version())
}
