# Mobile Devices SDK for developing cloud agents #

This SDK is an open source project by [Mobile Devices](http://www.mobile-devices.com/) intended to make development of agents in our cloud environment quick and easy.

## Installation ##

To save you from installing and managing the dependencies of this SDK, we advise you to use our VM (virtual machine) which contains all you need to run this SDK.

## Usage ##

The VM will automatically start the admin server on [http://localhost:5000](http://localhost:5000). If not, use the `ruby-agents-sdk` script:

``` bash
./ruby-agents-sdk start_admin
```

Once the admin server is started, access the nice GUI at [http://localhost:5000](http://localhost:5000) with your favorite browser. More documentation is available from this GUI.

## Need help? ##

### IRC ###
`irc.freenode.org`,  channel `#mdisdkvm`

## `ruby_agents_sdk` script

- Start the admin server: `./ruby-agents-sdk start_admin`
- Stop the admin server: `./ruby-agents-sdk stop_admin`
- Restart the admin server: `./ruby-agents-sdk restart_admin`

## License ##

This work is released under the GPLv2 license. See LICENSE.txt for details.
