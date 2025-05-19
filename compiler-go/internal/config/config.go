package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type VortexConfig struct {
	Compiler struct {
		OutputDir      string `yaml:"outputDir"`
		UseFlutterWind bool   `yaml:"useFlutterWind"`
	} `yaml:"compiler"`
}

func LoadConfig(sourceDir string) (*VortexConfig, error) {
	// First look in source directory
	configPath := findConfigFile(sourceDir)
	if configPath == "" {
		// Then look in current directory and parent directories
		configPath = findConfigFile("")
	}
	if configPath == "" {
		return nil, fmt.Errorf("vortex.config.yml not found")
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("error reading config file: %v", err)
	}

	var config VortexConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("error parsing config file: %v", err)
	}

	return &config, nil
}

func findConfigFile(dir string) string {
	if dir == "" {
		dir, err := os.Getwd()
		if err != nil {
			return ""
		}
		return findConfigInDir(dir)
	}
	return findConfigInDir(dir)
}

func findConfigInDir(dir string) string {
	// First try vortex.config.yml
	configPath := filepath.Join(dir, "vortex.config.yml")
	if _, err := os.Stat(configPath); err == nil {
		return configPath
	}

	// Then try vortex.config.yaml
	configPath = filepath.Join(dir, "vortex.config.yaml")
	if _, err := os.Stat(configPath); err == nil {
		return configPath
	}

	// If we're not in root directory, check parent
	if dir != "/" {
		parent := filepath.Dir(dir)
		if parent != dir {
			return findConfigInDir(parent)
		}
	}

	return ""
}
