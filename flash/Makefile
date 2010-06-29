##
## Makefile
## Login : <elthariel@rincevent>
## Started on  Thu Jun 17 23:25:07 2010 elthariel
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
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##

MXMLC		= $(FLEX_HOME)/bin/mxmlc

#TARGETS		= vidpublish.swf receivevideo.swf

all: flash

flash: publish receive
	cp -f receive_video/*.png public/images

publish:
	cd publish_video && $(MXMLC) vidpublish.mxml
	cp -f publish_video/vidpublish.swf public/publish_video.swf

receive:
	cd receive_video && $(MXMLC) receiveVideo.mxml
	cp -f receive_video/receiveVideo.swf public/receive_video.swf

clean:
	echo "Cleaning !.."
	rm -f public/publish_video.swf
	rm -f public/receive_video.swf
	rm -f receive_video/receiveVideo.swf
	rm -f publish_video/vidpublish.swf

re: clean all

.PHONY: all flash clean re receive publish
