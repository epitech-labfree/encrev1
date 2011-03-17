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
APP_ROOT = ENV['RED5_HOME'] + "/webapps/encrev1/"
$:.unshift APP_ROOT + "WEB-INF/classes/applications/"

require 'encre_auth'
require 'encre_poller'
require 'encre_stream'

#logger
require 'logger'
options = YAML::load_file APP_ROOT + '/platform.yml'
options[:logger] = STDOUT if options[:logger] == "STDOUT" || !options[:logger]
$log = Logger.new(options[:logger])
if (Logger::Severity::const_defined? options[:loglvl].upcase)
  $log.level = Logger.const_get(options[:loglvl].upcase.to_sym)
else
  $log.level = Logger::INFO  #default logger level
end

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

  attr_reader :appScope, :serverStream, :subscriber, :encre
  attr_writer :appScope, :serverStream, :subscriber

  def initialize
    #call super to init the superclass, in this case a Java class
    super

    $log.info "Initializing ENCRE VideoChat v1..."
    options = YAML::load_file APP_ROOT + '/platform.yml'
    $log.debug "options : #{options}"
    @encre = Encre::Platform::connect options
    @subscriber = Subscriber.new
  end

  def appStart(app)
    $log.info "...Done."
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
    @job = Encre::Poller.new(self)
    @rest_job = @schedulingService.addScheduledJob(1000, @job)

    super

    @encre.auth.server(app) != nil
  end

  def appConnect(conn, params)
    $log.info "Connection: ENCRE VideoChat v1"
    $log.info "\tScope:#{conn.get_scope.get_path}"
    # if conn.get_scope.get_path == "/default/encrev1"
    $log.info "\tMeeting:#{conn.get_scope.get_name}"
    if (params.length < 1)
      $log.error "Didn't supplied the necessary parameters (connect(url, uid, sid);)"
      return false;
    end
    $log.info "\tUid:#{params[0][0].to_s}"
    $log.info "\tSid:#{params[0][1].to_s}"

    measureBandwidth(conn)
    if conn.instance_of?(Red5::IStreamCapableConnection)
      $log.info "Got stream capable connection"
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
    $log.info "End of connection: ENCRE VideoChat v1"
    @encre.event.server_disconnect(conn)
    if appScope == conn.getScope && @serverStream != nil
      @serverStream.close
    end
    super
  end

  def roomJoin(client, scope)
    $log.info "Room Join. (#{scope.get_name})"

    if @encre.auth.join(client, scope)
      #emit event
      @encre.event.room_join(client, scope)
      true
    else
      false
    end
  end

  def roomLeave(client, scope)
    $log.info "Room Leave. (#{scope.get_name})"
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
    $log.info "streamBroadcastClose (#{stream.class})"
    @encre.event.stream_stopped(stream)

    if stream.get_save_filename
      $log.info "Stream file name : (#{stream.get_save_filename})"
      @encre.event.file_upload(stream.get_save_filename)
    end
  end

  def streamBroadcastStart(stream)
    $log.info "streamBroadcastStart (#{stream.class})"
    @encre.event.stream_started(stream)

    if @encre.auth.stream_record(stream)
      scope = stream.get_scope.get_name
      user_uid = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'user_uid'
      stream.save_as "#{scope}_#{rand(99999999999999999999)}_#{user_uid}", true
    end
  end

  def streamPlayItemPause(stream, item, position)
    $log.info "streamPlayItemPause (#{stream.class})"
  end

  def streamPlayItemPlay(stream, item, isLive)
    $log.info "streamPlayItemPlay (#{stream.class})"
  end

  def streamPlayItemResume(stream, item, position)
    $log.info "streamPlayItemResume (#{stream.class})"
  end

  def streamPlayItemSeek(stream, item, position)
    $log.info "streamPlayItemSeek (#{stream.class})"
  end

  def streamPlayItemStop(stream, item)
    $log.info "streamPlayItemStop (#{stream.class})"
  end

  def streamPublishStart(stream)
    $log.info "streamPublishStart (#{stream.class})"
  end

  def streamRecordStart(stream)
    $log.info "streamRecordStart (#{stream.class})"
  end

  def streamSubscriberClose(stream)
    $log.info "streamSubscriberClose (#{stream.class})"
    scope = stream.get_scope.get_name
    user_uid = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'user_uid'
    user_sid = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'user_sid'
    @subscriber.del_stream_subscriber(stream, scope, user_uid, user_sid)
    @subscriber.show_stream_subscriber
    # @encre.event.stream_unwatched(stream)
  end

  def streamSubscriberStart(stream)
    $log.info "streamSubscriberStart (#{stream.class})"
    scope = stream.get_scope.get_name
    user_uid = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'user_uid'
    user_sid = Java::OrgRed5ServerApi::Red5::get_connection_local.get_client.get_attribute 'user_sid'
    @subscriber.add_stream_subscriber(stream, scope, user_uid, user_sid)
    @subscriber.show_stream_subscriber
    # @encre.event.stream_watched(stream)
  end

  ############## End of IStreamAwareScopeHandler

  def addChildScope(scope)
    $log.info "Added a scope: #{scope.get_name}(#{scope.inspect}, #{scope.class})"
    true
  end

end
