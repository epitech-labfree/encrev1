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

class Hash
  def __context_to_string(c)
    res = c.shift.to_s
    c.each { |e| res += "[#{e}]" }
    res
  end

  def __url_map(h, context = [])
    res = []
    h.each do |k, v|
      c = context.dup << k
      if v.is_a? Hash
        res << __url_map(v, c)
      elsif v.respond_to? :to_s
        res << "#{__context_to_string c}=#{v}"
      end
    end
    res
  end

  def url_encode
    __url_map(self).join("&")
  end
end

module Encre
  class Conf
    attr_accessor :server, :port, :uid, :token, :method, :prefix, :sid
    def initialize(options)
      @server = options[:server]
      @port = options[:port]
      @method = options[:method]
      @prefix = options[:prefix]
      @token = options[:token]
      @uid = options[:uid]
    end

  end

  class Platform
    attr_reader :auth, :event, :conf, :file

    def self.connect(o = {})
      options = {:server => 'localpwet', :port => 4657, :method => 'http', :prefix => ''}.merge o
      conf = Encre::Conf.new(options)
      Encre::Platform.new(conf)
    end

    protected
    def initialize(conf)
      @conf = conf
      @auth = Encre::Auth.new(@conf)
      @event = Encre::Event.new(@conf)
#      @file = Encre::File.new(@conf)
    end
  end

  class Event
    def initialize(conf)
      @conf = conf
      @url = "#{@conf.method}://#{@conf.server}:#{@conf.port}#{@conf.prefix}"
    end

    # file upload, should be in different class File
    def file_upload(file)
      file["//"] = "/"
      file = ENV['RED5_HOME'] + "/webapps/encrev1/#{file}"
      request_url = "#{@url}/file/demo"
      request_url += "?uid=#{@conf.uid}&sid=#{@conf.sid}"
      $log.info "Request filename : #{request_url}"
      response = RestClient.put request_url, ""
      $log.info "--> Got reponse : #{respone}"
      file_name = JSON.parse(response.to_str)['result']
      if file_name
        $log.info "--> Got filename : #{file_name}"
        request_url = "#{@url}/file/demo/"
        request_url += file_name
        request_url += "?uid=#{@conf.uid}&sid=#{@conf.sid}"
        $log.info "Upload (#{file}) to Encre : #{request_url}"
        response = RestClient.put request_url, File.read(file), :content_type => 'application/x-shockwave-flash'
        $log.info "Delete #{file} ..."
        file = File.delete(file)
      else
        file_name = nil
      end
    rescue
      file_name = nil
      $log.info "... failed ! (check exception below)"
      $log.info $!      
    end



    # def event(euid, token, type, metadatas = {} , id = "", eventlink = "")
    # The event must have been validated by the encre platform server before pushing it (isvalid?)
    def event(event)
      ## check acl ?
      e = { :type => "" }
      e.merge! event

      request_url = "#{@url}/event/demo?"
      request_url += "uid=#{@conf.uid}&sid=#{@conf.sid}"
      request_url += "&" + e.url_encode
      $log.info "Sending an event to encre: #{request_url}"
      response = RestClient.post request_url, ""
      $log.info "--> Got response : #{response}"

      # The doc doesn't mention any error code or return value from this method
      true
    end

    def event_stream(stream, type, who = nil)
      client = stream.get_provider.get_connection.get_client
      if client.has_attribute('user_uid') && client.has_attribute('user_sid')
        conn = Java::OrgRed5ServerApi::Red5::get_connection_local
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        $log.info "Event stream : type -> #{type} user uid -> #{user_uid} and sid -> #{user_sid}"
        event(:type => type,
              :user_uid => user_uid,
              :user_sid => user_sid,
              :path => stream.get_scope.get_path,
              :room => stream.get_scope.get_name,
              :name => stream.get_published_name )
      else
        return false
      end
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
      $log.info "server connect event\n\n"
      if conn.get_client.has_attribute('user_sid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        $log.info "user uid -> #{user_uid} and sid -> #{user_sid}"
        event(:type => 'videochat_serverconnect_event', :user_uid => user_uid, :user_sid => user_sid)
      else
        return false
      end
    end
    
    def server_disconnect(conn)
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        
        event(:type => 'videochat_serverdisconnect_event', :user_uid => user_uid, :user_sid => user_sid)
      else
        return false
      end
    end

    def room_join(client, scope)
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        
        event(:type => 'videochat_roomjoin_event',
              :user_uid => user_uid, :user_sid => user_sid,
              :path => scope.get_path, :room => scope.get_name)
      else
        return false
      end
    end
    
    def room_leave(client, scope)
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        
        event(:type => 'videochat_roomleave_event',
              :user_uid => user_uid, :user_sid => user_sid,
              :path => scope.get_path, :room => scope.get_name)
      else
        return false
      end
    end
  end

  class Auth
    def initialize(conf)
      @conf = conf
      @url = "#{@conf.method}://#{@conf.server}:#{@conf.port}#{@conf.prefix}"
    end

    def server(scope)
      $log.info "Authorizing from ENCRE server (#{scope.get_path}) on #{@url}/presence/#{@conf.uid} ..."
      $log.info "With uid : [#{@conf.uid}] and token : [#{@conf.token}]."
      begin
        r = RestClient.post("#{@url}/presence?uid=#{@conf.uid}&credential=#{@conf.token}", '')
        @conf.sid = JSON.parse(r.to_str)['result']
        if @conf.sid
          $log.info "... Authorizarion sid is #{@conf.sid}"
        else
          @conf.sid = nil
        end
      rescue
        @conf.sid = nil
        $log.info "... failed ! (check exception below)"
        $log.info $!
      end

      @conf.sid
    end

    def auth(user, event_type, scope)
      $log.debug " Getting uid #{user[:uid]} and sid #{user[:sid]}"
      # request = "#{@url}/token/#{@conf.token}/isvalid?"
      # request += "token=#{client_token}"
      # request += "&type=#{event_type}"
      # request += "&scope=#{scope}"
      # Currently not implemented/documented by Encre platform.
      # Will be available soon, with a new semantic
      # puts "Executing this request : #{request}."
      # response = RestClient.get request
      # puts "--> Got response: #{response}"
      # return false if JSON.parse(response.to_str).has_key? 'error'
      true
    end

    def connection(conn, params)
      ## get /info
      user_uid = params[0][0].to_s.delete '[]'
      user_sid = params[0][1].to_s.delete '[]'
      $log.debug " Getting uid #{user_uid} and sid #{user_sid}"
      conn.get_client.set_attribute('user_uid', user_uid)
      conn.get_client.set_attribute('user_sid', user_sid)
      auth(user = {:uid => user_uid, :sid => user_sid }, 'videochat_connect', '')
    end

    def join(client, scope)
      ## if user in scope[roster] check acl
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
          auth(user = {:uid => user_uid, :sid => user_sid }, 'videochat_join', scope.get_name)
      else
        return false
      end
    end
    
    def stream_auth(scope, name, type)
      # check scope
      # FIXME Check from threading issues.
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        
        auth(user = {:uid => user_uid, :sid => user_sid }, type, scope.get_name)
      else
        return false
      end
    end

    def stream_publish(scope, name, mode)
            # check scope
      stream_auth scope, name, 'videochat_streamstarted'
    end

    def stream_watch(scope, name, start, length, flush)
            # check scope
      stream_auth scope, name, 'videochat_streamwatched'
    end

    def stream_record(stream)
      # a revoir
      # FIXME Check from threading issues.
      conn = Java::OrgRed5ServerApi::Red5::get_connection_local
      if conn.get_client.has_attribute('user_uid') && conn.get_client.has_attribute('user_sid')
        user_uid = conn.get_client.get_attribute('user_uid').to_s
        user_sid = conn.get_client.get_attribute('user_sid').to_s
        
        auth(user = {:uid => user_uid, :sid => user_sid }, 'videochat_streamrecorded', stream.get_scope.get_name)
      else
        return false
      end
    end
    
  end
end

