Pantry: Modern DevOps Automation
================================

[![Build Status](https://travis-ci.org/pantry/pantry.png)](https://travis-ci.org/pantry/pantry) [![Code Climate](https://codeclimate.com/github/pantry/pantry.png)](https://codeclimate.com/github/pantry/pantry)

Pantry takes the tedium out of setting up a DevOps stack by providing framework for storing, sharing, and running server provisioning and configuration. Whether your stack is Chef or Puppet, Docker or Packer, or any mix of tools, Pantry doesn't care!

## Installation

Install Pantry via Rubygems on all servers and local machines:

    gem install pantry

## Requirements

Pantry depends on [Celluloid](http://celluloid.io) and [ZeroMQ](http://zeromq.org/). Pantry is built for Ruby 2.0 and later and requires Rubygems 2.1 and later.

## Usage

Pantry has three main aspects: the Server, a Client, and the CLI. Pantry provides command-line tools for all of these.

Starting the Server: `pantry-server -c /path/to/server.yml`

Starting a Client: `pantry-client -c /path/to/client.yml`

Running the CLI: `pantry --help`

For more information, see [Getting Started](http://pantryops.org/getting_started.html).

## Documentation

The Documentation for Pantry is available at http://pantryops.org and the RDoc is served up at [rdoc.info/pantry](http://rubydoc.info/github/pantry/pantry/master/frames).

## Available Plugins

* [Pantry Chef](https://github.com/pantry/pantry-chef) -- Configure Pantry Clients with Chef

## Project Details

* Built and Maintained by [Collective Idea](http://collectiveidea.com)
* Hosted on Github [pantry/pantry](https://github.com/pantry/pantry)
* File bug reports on the [Issue tracker](https://github.com/pantry/pantry/issues)

## Contributing

* Fork this repository on Github
* Make your changes and send us a Pull Request
* All Pull Requests must contain tests
* Pull Request tests must pass before being accepted

## License

Pantry is distributed under the MIT License. See LICENSE for more details.
