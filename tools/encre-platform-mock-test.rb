#! /usr/bin/env ruby
## encre-platform-mocker-test.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 11:36:25 2010 elthariel
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

require 'rubygems'
require 'json'
require 'rest_client'

def auth(client_token, event_type, scope)
  request = "http://localhost:4567/token/#{@token}/isvalid?"
  request += "token=#{client_token}"
  request += "&type=#{event_type}"
  request += "&scope=#{scope}"
  response = RestClient.get request
  #puts JSON.parse(response.to_str)
  return false if JSON.parse(response.to_str).has_key? 'error'
  true
end


puts "Authorizing from ENCRE server..."
r = RestClient.get 'http://localhost:4567/token/get'
@token = JSON.parse(r.to_str)['token']
if @token
  puts "\t... success: token is #{@token}"
else
  puts "\t... failure"
end

puts "Authorizing videochat_connect on ENCRE server..."
if auth('token1', 'videochat_connect', '')
  puts "\t... success"
else
  puts "\t... failure"
end

puts "Authorizing videochat_join on ENCRE server..."
if auth('token1', 'videochat_join', 'room1')
  puts "\t... success"
else
  puts "\t... failure"
end

