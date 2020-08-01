/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Example Go Config source released under MIT License
 * Copyright (c) 2020 Vic Shóstak and Jordan Gregory
 * https://github.com/koddr/example-go-config-yaml/blob/master/LICENSE
 * https://dev.to/ilyakaznacheev/a-clean-way-to-pass-configs-in-a-go-application-1g64
 * https://dev.to/koddr/let-s-write-config-for-your-golang-web-app-on-right-way-yaml-5ggp */

package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/spyd3rweb/hsmocsp"
)

// parseFlags will create and parse the CLI flags
// and return the path to be used elsewhere
func parseFlags() (string, error) {
	// String that contains the configured configuration path
	var configPath string

	// Set up a CLi flag called "-config" to allow users
	// to supply the configuration file
	flag.StringVar(&configPath, "config", ".config/hsmocsp/config.yaml", "path to config file")

	// Actually parse the flags
	flag.Parse()

	// Return the configuration path
	return configPath, nil
}

func main() {
	// Generate our config based on the config supplied
	// by the user in the flags
	cfgPath, err := parseFlags()
	if err != nil {
		flag.PrintDefaults()
		os.Exit(1)
	}

	cfg, err := hsmocsp.NewConfig(cfgPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing config '%s': %v", cfgPath, err)
		os.Exit(1)
	}
	//runtime.Breakpoint()
	// fmt.Printf("%+v", cfg)

	// Run the server
	cfg.Run()

}
