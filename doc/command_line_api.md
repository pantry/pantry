Command Line API
================

Example command line incantations based on regular use

## [Options]

All pantry commands filter by the following options:

    [application] [environment] [type]

These may not all be required, depending on how detailed the identity each client takes. The order is important, it's
in increasing specificity.

## $HOME/.pantry .pantry

Some parameters to the `pantry` command can be pre-set for the entire system ($HOME/.pantry) or for the project
in question (.pantry).


#### SSH into Client

    pantry [options] ssh

Asks the Server for the fully qualified FQDN of the client that matches the options given, then exec's SSH with that
domain assuming SSH config is configure properly, opening up an SSH connection.

If multiple clients are found asks which server to SSH into.

#### List all Clients

    pantry [options] status

Finds all clients that match the options, displays their current settings and status.

TODO: define "status". Something like `knife status` of "last check in?"

#### Execute Command

    pantry [options] execute [command]

Executes the given `command` on all servers that match the options.

#### Sudo Execute Command

    pantry [options] sudo [command]

    pantry [options] execute sudo [command]  ???

For commands that need sudo access, use this specific version. This will ask for the sudo password (if needed) and
pass that along to the servers.
