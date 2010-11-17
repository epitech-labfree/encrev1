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

  def initialize(app)
    @app = app
    @mutex = Mutex.new
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
