##
## encre_poller.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jul  8 11:36:17 2010 elthariel
## $Id$
##
## Author(s):
##  - Julien 'Lta' BALLET <j.ballet@labfree.org>
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
require 'yaml'
require 'thread'
require 'json'

require 'active_record'

module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.scheduling"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
end

api_root = ENV['RED5_HOME'] + "/webapps/encrev1/api/"
db_config = YAML::load(File.open(api_root + "database.yml"))
db_config['database'] = api_root + db_config['database'] if db_config['adapter'] =~ /sqlite/
db_config['adapter'] = 'jdbc' + db_config['adapter']

ActiveRecord::Base.establish_connection(db_config)

module Encre
class ApiEvent < ActiveRecord::Base
end

class Poller
  include Red5::IScheduledJob

  def initialize(application)
    @application = application
    @mutex = Mutex.new
  end

  def videostream_unmute_broadcast(metadatas)
    $log.info "Unmute broadcast event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_broadcast(metadatas['id_stream'], metadatas['eutoken'])
        stream.start
        $log.info "Done !"
      else
        $log.info "No broadcast found."
      end
    end
  end

  def videostream_mute_broadcast(metadatas)
    $log.info "Mute broadcast event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_broadcast(metadatas['id_stream'], metadatas['eutoken'])
        stream.stop
        $log.info "Done !"
      else
        $log.info "No broadcast found."
      end
    end
  end

  def videostream_muteaudio_subscriber(metadatas)
    $log.info "Mute audio subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_subscriber(metadatas['id_stream'], metadatas['eutoken'])
        stream.receive_audio(false)
        $log.info "Done !"
      else
        $log.info "No subscriber found."
      end
    end
  end

  def videostream_unmuteaudio_subscriber(metadatas)
    $log.info "Unmute audio subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_subscriber(metadatas['id_stream'], metadatas['eutoken'])
        stream.receive_audio(true)
        $log.info "Done !"
      else
        $log.info "No subscriber found."
      end
    end
  end

  def videostream_mutevideo_subscriber(metadatas)
    $log.info "Mute video subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_subscriber(metadatas['id_stream'], metadatas['eutoken'])
        stream.receive_video(false)
        $log.info "Done !"
      else
        $log.info "No subscriber found."
      end
    end
  end

  def videostream_unmutevideo_subscriber(metadatas)
    $log.info "Unmute video subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.info "child: #{child}"
      if stream = @application.streamer.get_stream_subscriber(metadatas['id_stream'], metadatas['eutoken'])
        stream.receive_video(true)
        $log.info "Done !"
      else
        $log.info "No subscriber found."
      end
    end
  end
  
  def videostream_kicked_event(metadatas)
    $log.info "Kick subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      $log.debug "I've found: #{child_name}"
      child = @application.get_child_scope child_name.to_s
      $log.debug "child: #{child}"
      child.get_clients.each do |client|
        $log.info "client: #{client}"
        if client.has_attribute('encre_token')
          if client.get_attribute('encre_token') == metadatas['eutoken'] && child.get_name == metadatas['room']
            client.disconnect
            $log.info "Client: #{metadatas['token']} was kicked from Room: #{metadatas['room']}"
            return
         end
        end
      end
      $log.info "None Client with Token: #{metadatas['token']} Room: #{metadatas['room']}"
    end
  end

  def execute(service)
    if @mutex.try_lock
      begin
        events = ApiEvent.all
        if events
          events_ids = events.map {|x| x.id}
          ApiEvent.delete(events_ids)
          events.each do |x|
            $log.info "Received a json event via db"
            $log.info "#{x.id} :: #{x.event}"
            result = JSON.parse(x.event)
            $log.info "Event type: #{result['event']['type']}"
            if self.class.method_defined? result['event']['type'] #&& result['event']['metadatas']
              $log.info "Event found."
              $log.info "Metadatas : (#{result['event']['metadatas']})"
              send(result['event']['type'], result['event']['metadatas'])
            else
              $log.info "No event or metadata found."
            end
          end
        end
      rescue
        $log.error $!
      end
      @mutex.unlock
    end
  end
  


end
end
