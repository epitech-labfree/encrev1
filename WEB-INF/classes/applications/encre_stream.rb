## header ?

require 'java'
require 'rubygems'


module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
  include_package "org.red5.server.scheduling"
  include_package "org.red5.server.api.scheduling"
end


class Subscriber
  attr_reader :subscriber


  def initialize
    @subscriber = []
  end

  def add_stream_subscriber(stream, scope, token)
    e = {:stream => stream,
                :scope => scope,
                :token => token }
    @subscriber.push(e)
  end

  def del_stream_subscriber(stream, scope, token)
        e = {:stream => stream,
                :scope => scope,
                :token => token }
    @subscriber.delete(e)
  end

  def show_stream_subscriber
    @subscriber.each do |e|
      $log.info "Subscriber: scope #{e[:scope]}, token #{e[:token]}"
    end
  end
  
  def get_stream_subscriber(scope, token)
    @subscriber.each do |e|
      if e[:scope] == scope && e[:token]
        return e[:stream]
      end
    end
    return false
  end

end
