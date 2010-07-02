#! /usr/bin/env ruby
## encre-platform-mocker.rb
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 11:10:18 2010 elthariel
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
require 'json'
require 'sinatra'

conf = {:red5_token => 'Keiqu0Iecouc4kiYuaF6ea3u',
        :auth => {'token1' => {'videochat_connect' => {'' => true},
                               'videochat_join' => {'room1' => true,
                                                   'room2' => false},
                               'videochat_streamstarted' => {'room1' => true,
                                                             'room2' => false},
                               'videochat_streamwatched' => {'room1' => true,
                                                             'room2' => true}},
                  'token2' => {'videochat_connect' => {'' => true},
                               'videochat_join' => {'room1' => true,
                                                   'room2' => true},
                               'videochat_streamstarted' => {'room1' => false,
                                                             'room2' => true},
                               'videochat_streamwatched' => {'room1' => true,
                                                             'room2' => true}},
                  'token3' => {'videochat_connect' => {'' => true},
                               'videochat_join' => {'room1' => false,
                                                   'room2' => true},
                               'videochat_streamstarted' => {'room1' => true,
                                                             'room2' => false},
                               'videochat_streamwatched' => {'room1' => false,
                                                             'room2' => false}}}}


get '/token/get' do
  {:token => conf[:red5_token]}.to_json
end

get "/token/:btoken/isvalid" do
  if params[:btoken] == conf[:red5_token]
    puts "#> Request token is #{params[:token]}, Type is #{params[:type]} and scope is #{params[:scope]}"
    if conf[:auth][params[:token]] and conf[:auth][params[:token]][params[:type]] and conf[:auth][params[:token]][params[:type]][params[:scope]] == true
      puts "--> OK\n\n"
      return {:result => 'ok'}.to_json
    end
  end
  puts "--> NOK\n\n"
  {:error => 'not_authorized'}.to_json
end

post "/event/push?" do
  puts "Token is #{params['token']}"
  puts @request.body.string
  {:ok => 'i got it'}.to_json
end
