##
## encre_auth.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 12:10:03 2010 elthariel
## $Id$
##
## Author(s):
##  - Julien BALLET <j.ballet@labfree.org>
##
## Copyright (C) 2010 Epitech
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##

require 'java'
require 'rubygems'
require 'rest_client'
require 'json'

module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
end

module Encre
  class Conf
    attr_accessor :server, :method, :port, :token

    def initialize(server, method, port)
      @server = server
      @method = method
      @port = port
      @token = "NotAnyTokenYet"
    end
  end

  class Platform
    attr_reader :auth, :event, :conf

    def self.connect(server = 'localhost', port = 4567, method = 'http')
      conf = Encre::Conf.new(server, method, port)
      Encre::Platform.new(conf)
    end

    protected
    def initialize(conf)
      @conf = conf
      @auth = Encre::Auth.new(@conf)
      @event = Encre::Event.new(@conf)
    end
  end

  class Event
    def initialize(conf)
      @conf = conf
      @url = "#{@conf.method}://#{@conf.server}:#{@conf.port}"
    end

    # def event(euid, token, type, metadatas = {} , id = "", eventlink = "")
    # The event must have been validated by the encre platform server before pushing it (isvalid?)
    def event(event)
      timecode = Time.now.tv_sec
      e = {:timecode => timecode,
        :id => "#{event[:type]}_#{timecode}_#{rand(99999)}",
        :eventLink => "",
        :metadata => ""
      }
      e.merge! event

      request_url = "#{@url}/event/push?"
      request_url += "token=#{@conf.token}"
      response = RestClient.post request_url, e.to_json, :content_type => :json, :accept => :json

      # The doc doesn't mention any error code or return value from this method
      true
    end

    def event_stream(stream, type, who = nil)
      client = stream.get_provider.get_connection.get_client
      return unless client.has_attribute 'encre_token'
      token = client.get_attribute 'encre_token'

      event(:type => type,
            :metadata => {:eutoken => token,
              :path => stream.get_scope.get_path,
              :room => stream.get_scope.get_name,
              :name => stream.get_published_name })
    end

    def stream_watched(stream)
      event_stream(stream, 'videochat_streamwatched_event')
    end

    def stream_unwatched(stream)
      event_stream(stream, 'videochat_streamunwatched_event')
    end

    def stream_started(stream)
      event_stream(stream, 'videochat_streamstarted_event')
    end

    def stream_stopped(stream)
      event_stream(stream, 'videochat_streamstopped_event')
    end

    def server_connect(conn)
      puts "server connect event\n\n"
      return false unless conn.get_client.has_attribute('encre_token')
      token = conn.get_client.get_attribute('encre_token').to_s

      event(:type => 'videochat_serverconnect_event', :metadata => {:eutoken => token})
    end

    def server_disconnect(conn)
      return false unless conn.get_client.has_attribute('encre_token')
      token = conn.get_client.get_attribute('encre_token').to_s

      event(:type => 'videochat_serverdisconnect_event', :metadata => {:eutoken => token})
    end

    def room_join(client, scope)
      return false unless client.has_attribute('encre_token')
      token = client.get_attribute('encre_token').to_s

      event(:type => 'videochat_roomjoin_event',
            :metadata => {:path => scope.get_path, :room => scope.get_name,
              :eutoken => token })
    end

    def room_leave(client, scope)
      return false unless client.has_attribute('encre_token')
      token = client.get_attribute('encre_token').to_s

      event(:type => 'videochat_roomleave_event',
            :metadata => {:path => scope.get_path, :room => scope.get_name,
              :eutoken => token })
    end
  end

  class Auth
    def initialize(conf)
      @conf = conf
      @url = "#{@conf.method}://#{@conf.server}:#{@conf.port}"
    end

    def server(scope)
      puts "Authorizing from ENCRE server (#{scope.get_path})..."
      r = RestClient.get "#{@url}/token/get"
      @conf.token = JSON.parse(r.to_str)['token']
      if @conf.token
        puts "... Authorizarion token is #{@conf.token}"
      else
        puts "... failed !"
      end
      @conf.token
    end

    def auth(client_token, event_type, scope)
      request = "#{@url}/token/#{@conf.token}/isvalid?"
      request += "token=#{client_token}"
      request += "&type=#{event_type}"
      request += "&scope=#{scope}"
      response = RestClient.get request
      return false if JSON.parse(response.to_str).has_key? 'error'
      true
    end

    def connection(conn, params)
      token = params[0].to_s.delete '[]'
      conn.get_client.set_attribute('encre_token', token)
      # seems useless: FIXME, get and set the real euid
      # conn.get_client.set_attribute('encre_uid', "123456789")
      auth(token, 'videochat_connect', '')
    end

    def join(client, scope)
      return false unless client.has_attribute('encre_token')
      token = client.get_attribute('encre_token').to_s
      auth(token, 'videochat_join', scope.get_name)
    end

    def stream_auth(scope, name, type)
      # FIXME Check from threading issues.
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      return false unless conn.get_client.has_attribute('encre_token')
      token = conn.get_client.get_attribute('encre_token')

      auth(token, type, scope.get_name)
    end

    def stream_publish(scope, name, mode)
      stream_auth scope, name, 'videochat_streamstarted'
    end

    def stream_watch(scope, name, start, length, flush)
      stream_auth scope, name, 'videochat_streamwatched'
    end

  end

end

