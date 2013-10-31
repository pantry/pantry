module Pantry

  def self.logger(destination = STDOUT)
    @@logger ||= (Celluloid.logger = Logger.new(destination))
  end

end
