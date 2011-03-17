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

module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.scheduling"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
end

module Encre

class UCLongPoller
  attr_writer :running

  def initialize(platform)
    @encre = platform

    @running = true
    @mutex = Mutex.new
    @q = Array.new
    @timestamp = 0
    @thread = Thread.new { self.run }
  end

  def run
    begin
      puts "Starting Encre Long Poller thread."
      @timestamp = _get_time

      while running? do
        begin
          res = _fetch

          res.each do |e|
            @timestamp = e['datetime'] + 1 if (e['datetime'] >= @timestamp)
          end

          if res.length > 0
            @mutex.synchronize do
              @q.push res
              @q.flatten!
            end
          end
        rescue
          puts "Exception in UCLongPoller loop: #{$!}"
          puts $!.backtrace
        end
      end
    rescue
      puts "Exception in EncreLongPoller thread : #{$!}"
      puts $!.backtrace
    end
  end

  def events(max = 10)
    @mutex.synchronize do
      if @q.length <= max
        res = @q.dup
        @q.clear
        res
      else
        res = @q[0, max - 1]
        @q = @q[max, @q.length]
        res
      end
    end
  end

  def running?
    @running
  end

  private
  def _fetch
    url = "#{_url}/event?#{_url_auth}&#{_event_types}&start=#{@timestamp}&_async=lp"
    puts "## #{url}"
    begin
      res = RestClient.get url
      res = JSON.parse res
      puts res
      res["result"]
    rescue
      []
    end
  end

  def _get_time
    puts "#{_url}/time"
    res = RestClient.get "#{_url}/time"
    res = JSON.parse res
    res["result"].to_i

  end

  def _url
    conf = @encre.conf
    "#{conf.method}://#{conf.server}:#{conf.port}#{conf.prefix}"
  end

  def _url_auth
    "uid=#{@encre.conf.uid}&sid=#{@encre.conf.sid}"
  end

  def _event_types
    res = "type="
    res += ["videochat_roomleave_event",
            "videochat_roomjoin_event"].join ','
  end
end

class Poller
  include Red5::IScheduledJob

  def initialize(application)
    @application = application
    @mutex = Mutex.new
    @elp = UCLongPoller.new(application.encre)
  end

  def videostream_unmute_broadcast(metadatas)
    $log.info "Unmute broadcast event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      child = @application.get_child_scope child_name.to_s
      @application.subscriber.subscriber.each do |subscriber|
        subscriber[:stream].receive_video(true)
        subscriber[:stream].receive_audio(true)
        $log.info "Subscriber scope:(#{subscriber[:scope]}) uid:(#{subscriber[:uid]}) video unmuted."
      end
      $log.info "Done !"
    end
  end

  def videostream_mute_broadcast(metadatas)
    $log.info "mute broadcast event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      child = @application.get_child_scope child_name.to_s
      @application.subscriber.subscriber.each do |subscriber|
        subscriber[:stream].receive_video(false)
        subscriber[:stream].receive_audio(false)
        $log.info "Subscriber scope:(#{subscriber[:scope]}) uid:(#{subscriber[:uid]}) video unmuted."
      end
      $log.info "Done !"
    end
  end

  def videostream_muteaudio_subscriber(metadatas)
    $log.info "Mute audio subscriber event"
    @application.get_child_scope_names.each do |child_name|
      child_name = child_name[1, child_name.length - 1] if child_name =~ /:/
      child = @application.get_child_scope child_name.to_s
      if stream = @application.subscriber.get_stream_subscriber(metadatas['id_stream'], metadatas['uid'])
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
      if stream = @application.subscriber.get_stream_subscriber(metadatas['id_stream'], metadatas['uid'])
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
      child = @application.get_child_scope child_name.to_s
      if stream = @application.subscriber.get_stream_subscriber(metadatas['id_stream'], metadatas['uid'])
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
      child = @application.get_child_scope child_name.to_s
      if stream = @application.subscriber.get_stream_subscriber(metadatas['id_stream'], metadatas['uid'])
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
        if client.has_attribute('user_uid') && client.has_attribute('user_sid')
          if client.get_attribute('user_uid') == metadatas['uid'] && child.get_name == metadatas['room']
            client.disconnect
            $log.info "Client: #{metadatas['uid']} was kicked from Room: #{metadatas['room']}"
            return
         end
        end
      end
      $log.info "None Client with Uid: #{metadatas['uid']} Room: #{metadatas['room']}"
    end
  end

  def execute(service)
    begin
      events = @elp.events

      events.each do |e|
        $log.info "Received a json event from ucengine"
        $log.info e
        $log.info "Event type: #{e['type']}"
        if self.class.method_defined? e['type']
          $log.info "Event found."
          $log.info "Metadatas : (#{e['metadatas']})"
          send(e['type'], e['metadatas'])
        else
          $log.info "No event or metadata found."
        end
      end
    rescue
      puts "Error in ScheduledService : #{$!}"
      puts $!.backtrace
    end
  end

end
end
