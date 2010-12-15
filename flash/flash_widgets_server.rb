#! /usr/bin/ruby
## flv_server.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 15:27:55 2010 elthariel
## $Id$
##
## Author(s):
##  - Julien BALLET <j.ballet@labfree.epitech.eu>
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

require 'rubygems'
require 'haml'
require 'sinatra'

set :haml, {:format => :html5 }

before do
    headers['Cache-Control'] = 'no-cache'
end


get '/' do
  haml :index
end

get '/view' do
  @full_url = "#{params[:server]}/#{params[:room]}"
  haml :view
end

get '/publish' do
  @full_url = "#{params[:server]}/#{params[:room]}"
  # @full_url = "#{params[:server]}"
  haml :publish
end

