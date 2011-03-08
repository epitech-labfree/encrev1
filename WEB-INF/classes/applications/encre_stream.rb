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

  def add_stream_subscriber(stream, scope, user_uid, user_sid)
    e = {:stream => stream,
                :scope => scope,
                :user_uid => user_uid,
                :user_sid => user_sid }
    @subscriber.push(e)
  end

  def del_stream_subscriber(stream, scope, user_uid, user_sid)
        e = {:stream => stream,
                :scope => scope,
                :user_uid => user_uid,
                :user_sid => user_sid }
    @subscriber.delete(e)
  end

  def show_stream_subscriber
    @subscriber.each do |e|
      $log.info "Subscriber: scope #{e[:scope]}, user_uid #{e[:user_uid]}, user_sid #{e[:user_sid]}"
    end
  end
  
  def get_stream_subscriber(scope, user_uid, user_sid)
    @subscriber.each do |e|
      if e[:scope] == scope && e[:user_uid] && e[:user_sid]
        return e[:stream]
      end
    end
    return false
  end

end
