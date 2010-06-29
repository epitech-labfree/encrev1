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
    end
  end

  class Event
    def initialize(conf)
      @conf = conf
    end

    def event(type, metadatas = {} , id = "", eventlink = "")
      e = {:type => type,
        :timecode => Time.now.tv_sec,
        :id => id,
        :eventLink => eventlink,
        :metadatas => metadatas}
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
      auth(token, 'videochat_connect', '')
    end

    def join(client, scope)
      return false unless client.has_attribute('encre_token')
      token = client.get_attribute('encre_token').to_s
      auth(token, 'videochat_join', scope.get_name)
    end
  end

end

