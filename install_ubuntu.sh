#!/bin/sh
##
## install_ubuntu.sh
## Login : <elthariel@hydre.freelab.lab.epitech.eu>
## Started on  Tue Sep 14 15:27:33 2010 Julien 'Lta' BALLET
## $Id$
##
## Author(s):
##  - Julien 'Lta' BALLET <elthariel@gmail.com>
##
## Copyright (C) 2010 Julien 'Lta' BALLET
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

DESTDIR=$HOME/code/encre
RED5_VERSION=0.9.1
FLEX_HOME=$DESTDIR/flex

echo "###############################"
echo "Installing system dependencies..."
echo "You will be prompted for your password by sudo"
echo "###############################"

yes | sudo apt-get install openjdk-6-jdk ant git-core           \
                build-essential unzip sqlite3 libsqlite3-0      \
                libsqlite3-dev ruby1.8 ruby1.8-dev ruby         \
                rake rubygems1.8 jruby1.2 wget


echo "###############################"
echo "Installing Ruby dependencies..."
echo "You might be prompted for your password by sudo"
echo "###############################"

#sudo gem install --no-ri --no-rdoc gemcutter sinatra haml json rest-client sqlite3-ruby mongrel
#sudo gem install --no-ri --no-rdoc --version "< 3.0.0" activesupport activerecord

echo "###############################"
echo "Installing JRuby dependencies..."
echo "###############################"
#jruby -S gem install --no-ri --no-rdoc --version "< 3.0.0" activesupport activerecord
#jruby -S gem install --no-ri --no-rdoc rest-client json_pure jruby-openssl jdbc-sqlite3 \
#                activerecord-jdbcsqlite3-adapter activerecord-jdbc-adapter haml

echo "###############################"
echo "Installing FLEX 4 SDK..."
echo "###############################"
sudo mkdir -p $FLEX_HOME
cd $FLEX_HOME
sudo wget http://fpdownload.adobe.com/pub/flex/sdk/builds/flex4/flex_sdk_4.0.0.14159_mpl.zip
sudo unzip flex_sdk_4.0.0.14159_mpl.zip

echo "###############################"
echo "Creating destination folder: $DESTDIR ..."
echo "###############################"
mkdir -p $DESTDIR
cd $DESTDIR

echo "###############################"
echo "Dowloading Red 0.9.x, encre flavor..."
echo "###############################"

wget http://github.com/downloads/epitech-labfree/encrev1/red5-encre-$RED5_VERSION.tar.gz
echo "Unpacking..."
tar xzf red5-encre-$RED5_VERSION.tar.gz

export RED5_HOME=$DESTDIR/red5-$RED5_VERSION/


