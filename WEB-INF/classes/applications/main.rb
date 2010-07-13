## main.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 15:27:55 2010 elthariel
## $Id$
##
## Author(s):
##  - Paul GREGOIRE
##  - Julien BALLET <j.ballet@labfree.epitech.eu>
##
## Copyright (C) 2010 Epitech, Paul Gregoire
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

# JRuby - style
require 'java'
require 'rubygems'

# ENCRE video subcomponents/classes
#
# FIXME, find a better way to find the required classes
#
#puts ENV['RED5_HOME'] + "/webapps/encrev1/WEB-INF/classes/applications/"
app_root = ENV['RED5_HOME'] + "/webapps/encrev1/"
$:.unshift app_root + "WEB-INF/classes/applications/"
require 'encre_auth'
require 'encre_poller'

module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
  include_package "org.red5.server.scheduling"
  include_package "org.red5.server.api.scheduling"
end

#
# main.rb - Encre Video component
#
# @author Julien BALLET (EPITECH-Labfree), based on the work of Paul Gregoire
#

class Application < Red5::MultiThreadedApplicationAdapter
  #include Red5::IStreamAwareScopeHandler

  attr_reader :appScope, :serverStream
  attr_writer :appScope, :serverStream

  def initialize
    #call super to init the superclass, in this case a Java class
    super

    puts "Initializing ENCRE VideoChat v1..."
    @encre = Encre::Platform::connect
    # @schedulingService = Red5::QuartzSchedulingService.new
    # puts @schedulingService.inspect

  end

  def appStart(app)
    puts "...Done."
    #Saving our scope for later use
    @appScope = app

    # Registering play and publish auth handlers
    registerStreamPlaybackSecurity do |scope, name, start, len, flush|
      @encre.auth.stream_watch scope, name, start, len, flush
    end
    registerStreamPublishSecurity do |scope, name, mode|
      @encre.auth.stream_publish scope, name, mode
    end

    # Initializing our app scheduling service, using red5 global one
    @schedulingService = @appScope.get_context.get_bean(Red5::ISchedulingService::BEAN_NAME);
    #puts app.get_application_loader.inspect
    #get_root_context.get_beans_of_type(nil)
    @job = Encre::Poller.new
    @rest_job = @schedulingService.addScheduledJob(1000, @job)

    super

    @encre.auth.server(app) != nil
  end

  def appConnect(conn, params)
    puts "Connection: ENCRE VideoChat v1"
    puts "\tScope:#{conn.get_scope.get_path}"
    puts "\tRoom:#{conn.get_scope.get_name}"
    if (params.length < 1)
      puts "Didn't supplied the necessary parameters (connect(url, token);)"
      return false;
    end
    puts "\tToken:#{params[0].to_s}"

    measureBandwidth(conn)
    if conn.instance_of?(Red5::IStreamCapableConnection)
      puts "Got stream capable connection"
      # sbc = Red5::SimpleBandwidthConfigure.new
      # sbc.setMaxBurst(8388608)
      # sbc.setBurst(8388608)
      # sbc.setOverallBandwidth(8388608)
      # conn.setBandwidthConfigure(sbc)
    end

    if @encre.auth.connection(conn, params)
      @encre.event.server_connect(conn)
      super(conn, params)
    else
      false
    end
  end

  def appDisconnect(conn)
    puts "End of connection: ENCRE VideoChat v1"
    @encre.event.server_disconnect(conn)
    if appScope == conn.getScope && @serverStream != nil
      @serverStream.close
    end
    super
  end

  def roomJoin(client, scope)
    puts "Room Join. (#{scope.get_name})"

    if @encre.auth.join(client, scope)
      #emit event
      @encre.event.room_join(client, scope)
      true
    else
      false
    end
  end

  def roomLeave(client, scope)
    puts "Room Leave. (#{scope.get_name})"
    @encre.event.room_leave(client, scope)
  end

  def toString
    return "encrev1 Application Adapter"
  end

  def setScriptContext(scriptContext)
    puts "encrev1: setScriptContext"
  end

  def method_missing(m, *args)
    super unless @value.respond_to?(m)
    return @value.send(m, *args)
  end

  ############## IStreamAwareScopeHandler
  # def streamPublishStart(stream)
  #   puts "Somebody published a stream (#{stream.class})"
  # end

  # def streamBroadcastStart(stream)
  #   puts "Somebody published a stream (#{stream.class})"
  # end

  def streamBroadcastClose(stream)
    puts "streamBroadcastClose (#{stream.class})"
    @encre.event.stream_stopped(stream)

    if stream.get_save_filename
      puts "FIXME: Should push the file on the platform"
    end
  end

  def streamBroadcastStart(stream)
    puts "streamBroadcastStart (#{stream.class})"
    @encre.event.stream_started(stream)

    if @encre.auth.stream_record(stream)
      scope = stream.get_scope.get_name
      token = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'encre_token'
      stream.save_as "#{scope}__#{token}", true
    end
  end

  def streamPlayItemPause(stream, item, position)
    puts "streamPlayItemPause (#{stream.class})"
  end

  def streamPlayItemPlay(stream, item, isLive)
    puts "streamPlayItemPlay (#{stream.class})"
  end

  def streamPlayItemResume(stream, item, position)
    puts "streamPlayItemResume (#{stream.class})"
  end

  def streamPlayItemSeek(stream, item, position)
    puts "streamPlayItemSeek (#{stream.class})"
  end

  def streamPlayItemStop(stream, item)
    puts "streamPlayItemStop (#{stream.class})"
  end

  def streamPublishStart(stream)
    puts "streamPublishStart (#{stream.class})"
  end

  def streamRecordStart(stream)
    puts "streamRecordStart (#{stream.class})"
  end

  def streamSubscriberClose(stream)
    puts "streamSubscriberClose (#{stream.class})"
    # @encre.event.stream_unwatched(stream)
  end

  def streamSubscriberStart(stream)
    puts "streamSubscriberStart (#{stream.class})"
    # @encre.event.stream_watched(stream)
  end

  ############## End of IStreamAwareScopeHandler

  def addChildScope(scope)
    puts "Added a scope: #{scope.get_name}(#{scope.inspect}, #{scope.class})"
    true
  end

end
