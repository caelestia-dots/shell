package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"

	"github.com/otiai10/copy"
)

func main() {
	installPath := flag.String("path", "", "The path to install caelestia-shell to.")
	flag.Parse()

	if *installPath == "" {
		fmt.Println("Please provide an installation path with the -path flag.")
		os.Exit(1)
	}

	fmt.Printf("Installing caelestia-shell to %s\n", *installPath)

	fmt.Println("Cloning caelestia-shell repository...")
	cmd := exec.Command("git", "clone", "https://github.com/caelestia-dots/shell.git", *installPath)
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Error cloning repository: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Repository cloned successfully.")

	fmt.Println("Compiling beat_detector...")
	beatDetectorPath := *installPath + "/assets/beat_detector.cpp"
	cmd = exec.Command("g++", "-std=c++17", "-Wall", "-Wextra", "-o", "beat_detector", beatDetectorPath, "-lpipewire-0.3", "-laubio")
	cmd.Dir = *installPath
	err = cmd.Run()
	if err != nil {
		fmt.Printf("Error compiling beat_detector: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("beat_detector compiled successfully.")

	fmt.Println("Installing beat_detector...")
	err = os.MkdirAll("/usr/lib/caelestia", 0755)
	if err != nil {
		fmt.Printf("Error creating directory: %v\n", err)
		os.Exit(1)
	}

	err = os.Rename(*installPath+"/beat_detector", "/usr/lib/caelestia/beat_detector")
	if err != nil {
		fmt.Printf("Error moving beat_detector: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("beat_detector installed successfully.")

	configDir, err := os.UserConfigDir()
	if err != nil {
		fmt.Printf("Error getting user config directory: %v\n", err)
		os.Exit(1)
	}

	caelestiaConfigPath := configDir + "/quickshell/caelestia"
	fmt.Printf("Installing caelestia-shell to %s\n", caelestiaConfigPath)

	err = os.MkdirAll(caelestiaConfigPath, 0755)
	if err != nil {
		fmt.Printf("Error creating directory: %v\n", err)
		os.Exit(1)
	}

	err = copy.Copy(*installPath, caelestiaConfigPath)
	if err != nil {
		fmt.Printf("Error copying caelestia-shell: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("caelestia-shell installed successfully.")
}
