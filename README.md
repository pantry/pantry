Pantry
======

[ What follows is currently RDD, or Readme Driven Development ]

## What is it?

Pantry is a re-think and re-build of chef-server and chef-client. After years of working with chef-server, chef-client, and chef-solo, I feel that many real-world use cases just aren't handled in this stack. Pantry is designed to be a wrapper around the Chef ecosystem, to where a Pantry client is easily convertible to a raw chef-client or chef-solo. Pantry Server is currently planned to be API compliant to chef-server and handle all of the major chef components (cookbooks, roles, environments, nodes, etc) but that's about it.

## Why?

The short of it is, chef-server is far too complicated for what we at Collective Idea need. Following that some design decisions made by Opscode actively work against our requirements, which is sharing cookbooks across multiple applications, while ensuring that if an application we are managing needs to head elsewhere, that we can easily pull out the cookbooks for that application, bundle them up, and send the app/customer on its way with everything needed for continued management.

Our current "solution" is no solution at all. We have multiple repos with copied cookbooks for multiple applications. Every one of these cookbooks is in a different state and as we get more customers and applications this only gets harder to manage. Chef-Server's solution, however, has it's own serious problems. It's impossible to share cookbooks across Organizations, leading to a very annoying situation where cookbooks have to be uploaded multiple times.

One thing Pantry isn't, we aren't trying to build another provisioning tool. Puppet, Chef, SaltStack and Ansible all have that market pretty much saturated and all have very big, vibrant communities. It would be very hard to carve a new niche, solving many the same problems many before us have already solved.

### Why not Puppet, Salt, Ansible, etc?

Well first and foremost we've done a lot of work in Chef so we are very familiar with it. We like and work every day in Ruby so Chef cookbooks just feel natural, where as these three require using another language / templating system. Switching to another framework would require throwing away a ton of knowledge and spending a lot of time converting to the framework of choice.

Also, I have been looking through these other tools to see if they do solve the problem we have here at Collective Idea, and I don't think they do. We want to have a set of cookbooks shared across multiple applications. These applications are completely separate from each other and for many reasons should never even know about each other. This is the main problem Pantry is attempting to solve.

## How?

### Pantry Server

The Pantry Server is the brains of the whole operation. It stores Chef material (cookbooks, roles, etc), knows what clients are connected and how to talk to them, and triggers off jobs at clients while receiving data from clients appropriately.

#### Data Structures

Chef stuff

* Cookbooks
* Applications
* Environments
* Roles
* Data Bags

Server Stuff

* Nodes(?)
* Clients(?)

Management Stuff

* Users

#### Communication

##### Publish

Pantry Server exposes a ZMQ Publish socket down which command requests are blasted out to listening clients.

### Pantry Client

The Pantry Client is a functionality wrapper around chef-solo (chef-client? what does client do over solo outside of server communication?). The client can send and receive information and requests from the server and can converge the chef cookbooks according to role / environment / application.

#### Wrapping Chef

#### Communication

##### Subscribe

Pantry Clients Subscribe to the Server's Publish socket, listening against multiple streams to ensure that the Client receives only and exactly the messages meant for it.

## Security

There's nothing more important for this project than a secure communications protocol. Highly sensitive information, like passwords, will be transmitted across the network between server and clients. Building this yourself is a recipe for disaster, as the Salt team is quickly learning, but there's some fantastic developments lately that will make this a plug-in-play setup: ZeroMQ's CurveZMQ security architecture: http://curvezmq.org/ which comes with 0MQ 4. Current plan is to run this security system with full Server/Client public/private key identification verification.
