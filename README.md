Pantry
======

## What is it?

Pantry started as a re-think of chef-solo, chef-server and chef-client, and how this stack simply does not work for many common use cases. Pantry has from there morphed into a provisioning-agnostic server management tool composed of two main parts: An async communication layer between a Pantry Server and it's Clients, and a Provisioning layer for defining how Pantry Clients will configure their servers.

The overarching goal is that Pantry can be used by anyone, regardless of Chef, Puppet, Salt, Docker, Packer, etc. We've come to realize that the DevOps scene does have a lot of progress in many different fields, but until we can start bridging these fields we will continue to fight one-off piecemeal systems.

## Why?

First, at Collective Idea we manage a number of customer web applications. Each of these applications have multiple servers, all managed by chef cookbooks. However, we have had no way to nicely share these cookbooks, so they just get copied around and are now all different in subtle or big ways. The only known solution, chef-server, is not a good fit because it's way of segregating applications, Organizations, do not allow any sharing at all between them.

After spending a lot of time fighting various tools that attempt to make chef easier to manage, we realized that the tool to fix our problems doesn't exist yet, and thus Pantry was born.

One thing Pantry isn't, we aren't trying to build another provisioning tool. Puppet, Chef, SaltStack and Ansible all have that market pretty much saturated and all have very big, vibrant communities, and honestly, this market is solved. There's no need for another provisioning library. We need more ways to *use* these libraries.

In short, Pantry exists to fill a hole in DevOps management: how to work with multiple servers, across multiple applications, with the provisioning tool of your choice, without building out a ton of custom one-off scripts.

### Why not switch to Puppet, Salt, Ansible, etc?

Well first and foremost we've done a lot of work in Chef so we are very familiar with it. We like and work every day in Ruby so Chef cookbooks just feel natural, where as these three require using another language / templating system. Switching to another framework would require throwing away a ton of knowledge and spending a lot of time converting to the framework of choice.

Prior to starting Pantry we did look closely at each of these other offerings, and were unable to find a solution to our problems in any of them.

## How?

All communication between Clients and Servers is handled with a custom ZeroMQ topology.

![network_topology](https://github.com/collectiveidea/pantry/blob/master/doc/network_topology.dot.png)

### Pantry Server

The Pantry Server is the brains of the whole operation. All Clients connect to a Server, receive orders via the PUB/SUB sockets and respond back to the Server through the DEALER/ROUTER connection.

The Server also stores provisioning data for clients to request [WIP]

### Pantry Client

All actual work is done Clients. Each client can be configured with a number of identifiers:

* identity
  
  A unique identifier in the network. Commonly the server's hostname
  
* application

  Name of the application managed by this Client

* environment

  Name of the environment this Client manages (production, staging, etc)

* roles

  Any number of roles the server plays in the application (web, db, etc)
  
These identifiers are ordered in terms of rank-of-importance, but none of them need to be set. If `identity` is not set, it will default to the `hostname` of the server. The rest define which messages the Client receives over it's SUB socket. If no options are specified, the Client will receive all commands.

It is recommended that as many of these options are set to ensure a Client is a explicitly defined as possible.

##### 0MQ Pub/Sub

A quick aside. ZeroMQ implements Pub/Sub subscription mapping by very simple string prefix matching. The Client configuration is built around this idea, ensuring that it's trivial to choose as many or as few clients when sending a command.

For example, given a Client with the identity `app.host`, application `pantry`, environment `test`, and role `web`, it will listen on the following Publish streams:

    app.host
    pantry.test.web
    
Sending a command to this Client can be as explicit or general as wanted. Sending a command to the `pantry`, `pantry.test`, or `pantry.test.web` stream will all end up at this Client. Likewise a command can be targeted directly at this Client using the identity stream `app.host`.

## Security

There's nothing more important for this project than a secure communications protocol. Highly sensitive information, like passwords, will be transmitted across the network between server and clients. We fully understand the folly of building your own security, so we don't plan to. There is some fantastic developments lately in communication cryptography that's making its way into ZeroMQ 4: [CurveCP](http://curvecp.org/) and ZeroMQ's CurveZMQ security architecture: http://curvezmq.org/.
