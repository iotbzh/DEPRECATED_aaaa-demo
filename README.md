# AGL Advance Audio Agent Demo

## Dependencies

 * From AGL
   * afb_binder
   * audio-binding
   * mpdc-binding and AAAA bindings
 * Linux
   * Music Media Player
   * LUA script 5.3

## Installation

 Start installing MPD (Music Media Player) and edit
 sample configuration from to fit your config.

 Start 3 MPD instance (default port in demo config)
  * Multimedia port 6601
  * Navigation port 6602
  * Emergency port 6603

 Edit your demo json config file
```
conf.d/project/json.d/onload-audiodemo-config.json
```
Except if you change port, or if MPD is not running on localhost default config
should be fine.

 Edit start-demo-daemon.sh

 This file is a simple shell helper for you to get the right options to give to
 afb-daemon. The script support a debug mode where all bindings run under the
 same binder. Which is simpler to use with GDB. In Normal(install) mode, the
 application binder should be an independent process and talk through a Unix/WS
 under the control of SMACK and Cynara.

## Play with the configuration

The main configuration is the controller JSON file onload-audiodemo-config.json.
Then all action and business logic are coded in LUA script available under
`conf.d/project/lua.d`. On start the controller read and compile file under
alphabetic order.
