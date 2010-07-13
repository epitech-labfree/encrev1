#! /usr/bin/env ruby
## server.rb
## Login : <elthariel@rincevent>
## Started on  Tue Jul 13 16:53:19 2010 elthariel
## $Id$
##
## Author(s):
##  - elthariel <elthariel@gmail.com>
##
## Copyright (C) 2010 elthariel
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
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

require 'rubygems'
require 'yaml'
require 'active_record'
require 'json'

db_config = YAML::load_file 'database.yml'
ActiveRecord::Base.establish_connection(db_config)

class ApiEvent < ActiveRecord::Base
end

require 'sinatra'

post '/event/push' do
  ApiEvent.create :event => @request.body.string
end


