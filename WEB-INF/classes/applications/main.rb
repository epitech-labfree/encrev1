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
$:.unshift ENV['RED5_HOME'] + "/webapps/encrev1/WEB-INF/classes/applications/"
require 'encre_auth'

module Red5
  include_package "org.red5.server.api"
  include_package "org.red5.server.api.stream"
  include_package "org.red5.server.api.stream.support"
  include_package "org.red5.server.adapter"
  include_package "org.red5.server.stream"
end

#
# main.rb - Encre Video component
#
# @author Julien BALLET (EPITECH-Labfree), based on the work of Paul Gregoire
#
class Application < Red5::ApplicationAdapter

  attr_reader :appScope, :serverStream
  attr_writer :appScope, :serverStream

  def initialize
    #call super to init the superclass, in this case a Java class
    super
    puts "Initializing ENCRE VideoChat v1..."
    @auth = Encre::Auth.new
  end

  def appStart(app)
    puts "...Done."
    @appScope = app

    @auth.server(app) != nil
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

    if @auth.connection(conn, params)
      super(conn, params)
    else
      false
    end
  end

  def appDisconnect(conn)
    puts "End of connection: ENCRE VideoChat v1"
    if appScope == conn.getScope && @serverStream != nil
      @serverStream.close
    end
    super
  end

  def roomJoin(client, scope)
    puts "Room Join. (#{scope.get_name})"

    @auth.join(client, scope)
  end

  def toString
    return "encrev1: toString"
  end

  def setScriptContext(scriptContext)
    puts "encrev1: setScriptContext"
  end

  def method_missing(m, *args)
    super unless @value.respond_to?(m)
    return @value.send(m, *args)
  end

end

