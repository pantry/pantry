module Pantry

  # Commands are where the task-specific functionality is implemented. Commands are the
  # core of how Pantry works. There are two main types of commands: Server and Client, with
  # Command Line (CLI) handling fitting in with these as necessary. The overarching design of the
  # Command system is designed such that all knowledge required to understand a Command is contained
  # inside of said Command. Commands are free to run other Commands but a well built Command
  # is a single object that reads in the order of the execution throughout the entire request:
  #
  #   1. Command Line input processing and initial request (when applicable)
  #   2. Client / Server processing of the command and return value(s)
  #   3. Receipt of results, formatting and info display back to the user (when applicable)
  #
  # All commands must implement #perform. The important work of the Command is triggered through
  # this method. #perform is given the Message that triggered the command, and the values returned
  # from #perform will be packaged up and returned back to the requester when needed.
  #
  # The absolute simplest command one can write returns a static value:
  #
  #   class TheSimplestCommand < Pantry::Command
  #     def perform(message)
  #       42
  #     end
  #   end
  #
  # Commands are also responsible for creating the Pantry::Message that will be given to
  # #perform on the intended Client or Server recipient. By default an empty Message is created
  # with the Message#type set to the name of the Command's class. This can be customized using the
  # Command.message_type class method. There cannot be two Commands registered of the exact same name
  # or undefined behaviour will result.
  #
  # Customizing the Message for a given Command is handled with Command#to_message. Use
  # this method to add content to the Message before it is sent along the network:
  #
  #   class SimpleEcho < Pantry::Command
  #     def initialize(to_echo = nil)
  #       @to_echo = to_echo
  #     end
  #
  #     def perform(message)
  #       message.body[0]
  #     end
  #
  #     def to_message
  #       super.tap do |msg|
  #         msg << @to_echo
  #       end
  #     end
  #   end
  #
  # One important oddity to note about Command#initialize. Commands are constructed in two
  # situations: when the user triggers a command via the CLI, extra arguments not handled by
  # options are passed into the constructor via splat (covered below), and secondly when the
  # intended Client or Server receives a Message, the relevant Command object is constructed
  # with no parameters. As such, if a Command takes parameters in its initializer for the CLI,
  # then it must also support receiving no parameters.
  #
  # Commands can be further configured to be executable from the `pantry` CLI, including
  # description and Command-specific options, all of which will show up in `pantry`'s help output.
  # Lets add to the SimpleEcho example above to showcase how to configure the CLI options.
  #
  #   class SimpleEcho < Pantry::Command
  #     command "echo MESSAGE" do
  #       description "Echo the given MESSAGE back"
  #       option "-t", "--times TIMES", "Duplicate the message response by TIMES. Must be positive"
  #     end
  #
  #     def initialize(to_echo = nil)
  #       @to_echo = to_echo
  #     end
  #
  #     def prepare_message(options)
  #       raise "Option 'times' must be a positive non-zero number" if options[:times] <= 0
  #
  #       super.tap do |msg|
  #         msg << @to_echo
  #         msg << options[:times] || 1
  #       end
  #     end
  #
  #     def perform(message)
  #       message.body[0] * message.body[1]
  #     end
  #
  #     def receive_response(response)
  #       Pantry.ui.say(message.body[0])
  #       super
  #     end
  #   end
  #
  # There are a few new pieces here. We'll go over them one at a time. The first is configuring
  # the command line options themselves.
  #
  # The Command.command() class method is a very thin wrapper around Ruby's OptionParser library.
  # See OptParsePlus for details on how this adds command handling to OptionParser but in general
  # the syntax as defined for OptionParser is what you'll use in this block. Description strings
  # are post-processed to remove excessive whitespace so feel free to make that a multi-line, clean
  # block of text. The first line will be the summary and the rest will only show up on the command's
  # own help text (all commands are given "-h", "--help").
  #
  # Next, #to_message has been replaced with #prepare_message. This method takes the options parsed
  # from the command line and includes the Pantry global options as well (application, environment, roles).
  # Use this method to verify proper options, and to take care of any pre-flight steps before the Message
  # goes out. This also allows very fine-grained control over what Message is sent and what it contains.
  # This method must return the Message that will be sent over the network or raise an error that will
  # be displayed to the user and exit.
  #
  # The final aspect is #receive_response. By default a Command will assume that it's now finished as soon
  # as a single response comes back. To act on that response, override this method. It will be given the
  # response Message. This method must either call `super` or `finished` to trigger the Command as complete
  # or the `pantry` tool will hang and never complete.
  #
  # Receiving responses properly requires an understanding of how Pantry handles requests out to multiple
  # clients. Due to the fully async nature of Pantry, the CLI cannot know ahead of time how many Clients
  # a given request will be sent to. Thus, when executing a client command, the Pantry Server will first
  # return a message back to the CLI containing the identities of all Clients who received the message and
  # will respond. Then when each Client responds, those responses are forwarded through the Server back to
  # CLI. Thus, the SimpleEcho example above still isn't quite right, as the CLI needs to expect a minimum
  # of two response messages.
  #
  # Pantry comes with a complete Echo implementation that combines all of the above. See Pantry::Commands::Echo.
  #
  # Finally, all commands must be registered with Pantry before they will be available for execution.
  # Use Pantry.add_client_command or Pantry.add_server_command to register the Command class
  # in the Pantry system.
  class Command

    class << self
      # Expose this Command to the CLI and configure the options and information
      # that this Command needs from the CLI to function.
      #
      # See OptParsePlus for documentation
      def command(name, &block)
        @command_name   = name
        @command_config = block
      end
      attr_reader :command_name
      attr_reader :command_config
    end

    # Initialize this Command
    # Due to the multiple ways a Command is instantiated (via the CLI and from the Network stack)
    # any Command initializer must support being called with no parameters if it expects some.
    def initialize(*args)
    end

    # Set up the Message that needs to be created to send this Command
    # to the server to be processed. Used by the CLI. This method is given
    # the ClientFilter of which clients should respond to this message (if any) and
    # the extra arguments given on the command line.
    #
    # If work needs to be done prior to the network communication for CLI use,
    # override method to take care of that logic.
    #
    # The message returned here is then passed through the network to the appropriate
    # recipients (Clients, Server, or both) and used to trigger #perform on said
    # recipient.
    def prepare_message(options)
      to_message
    end

    # Run whatever this command needs to do.
    # All Command subclasses must implement this method.
    # If the message triggering this Command expects a response, the return
    # value of this method will be that response.
    def perform(message)
    end

    # When a message comes back from the server as a response to or because of
    # this command's #perform, the command object on the CLI will receive that
    # message here. By default we just mark ourselves finished.
    def receive_response(message)
      finished
    end

    # Send a request out, returning the Future which will eventually
    # contain the response Message
    def send_request(message)
      @server_or_client.send_request(message)
    end

    # Send a request out and wait for the response. Will return the response
    # once it is received.
    #
    # This is a blocking call.
    def send_request!(message)
      send_request(message).value
    end

    # Create a new Message from the information in the current Command
    def to_message
      Pantry::Message.new(self.class.message_type)
    end

    # Blocking call that returns when the command has completed
    # Can be given a timeout (in seconds) to wait for a response
    def wait_for_finish(timeout = nil)
      completion_future.value(timeout)
    end

    # Notify all listeners that this command has completed its tasks
    def finished
      completion_future.signal(OpenStruct.new(:value => nil))
    end

    # Is this command finished?
    def finished?
      completion_future.ready?
    end

    def completion_future
      @completion_future ||= Celluloid::Future.new
    end
    protected :completion_future

    # The Type of this command, used to differentiate Messages.
    # Defaults to the full scope of the name, though with the special
    # case of removing any "Pantry" related scoping such as Pantry::
    # and Pantry::Commands::
    #
    # This value must be unique across the system or the messages will not
    # be processed reliably.
    #
    # Override this for a custom name.
    def self.message_type
      self.name.gsub(/Pantry::Commands::/, '').gsub(/Pantry::/, '')
    end

    # Set a link back to the Server or Client that's handling
    # this command. This will be set by the CommandHandler before calling
    # #perform.
    def server_or_client=(server_or_client)
      @server_or_client = server_or_client
    end
    alias client= server_or_client=
    alias server= server_or_client=

    # Get the server or client object handling this command
    def server_or_client
      @server_or_client
    end
    alias server server_or_client
    alias client server_or_client

  end

end
