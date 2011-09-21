##
## uc-event-watcher.rb
## Login : <elthariel@rincevent>
## Started on  Tue Jun 28 13:06:09 2011 elthariel
## $Id$
##
## Author(s):
##  - elthariel <elthariel@gmail.com>
##
## Copyright (C) 2011 elthariel
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

require 'json'
require 'rest_client'

uid = 'root'
pass = 'root'
credential = RestClient.post "http://localhost:5280/api/0.5/presence?name=#{uid}&credential=#{pass}", ''
credential = JSON.parse credential
credential = credential['result']
uid = credential["uid"]
sid = credential["sid"]

puts "Logged with : uid = #{uid} && sid = #{sid}"

now = RestClient.get "http://localhost:5280/api/0.5/time"
now = JSON.parse(now)['result'].to_i

while true do
  events = RestClient.get "http://localhost:5280/api/0.5/event/test-meeting?uid=#{uid}&sid=#{sid}&start=#{now}&_async=lp"
  events = JSON.parse(events)['result']

  puts events

  if events[-1].respond_to? :has_key?
    now = events[-1]['datetime'] + 1
  end
end
