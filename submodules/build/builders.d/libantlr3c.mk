############################################################################
# libantlr.mk 
# Copyright (C) 2013  Belledonne Communications,Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################
libantlr_dir?=externals/antlr3/runtime/C
$(BUILDER_SRC_DIR)/$(libantlr_dir)/configure:
	cd $(BUILDER_SRC_DIR)/$(libantlr_dir) && ./autogen.sh

$(BUILDER_BUILD_DIR)/$(libantlr_dir)/Makefile: $(BUILDER_SRC_DIR)/$(libantlr_dir)/configure
	mkdir -p $(BUILDER_BUILD_DIR)/$(libantlr_dir)
	cd $(BUILDER_BUILD_DIR)/$(libantlr_dir)/ \
	&& PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
	$(BUILDER_SRC_DIR)/$(libantlr_dir)/configure -prefix=$(prefix) --host=$(host) ${library_mode}  

build-libantlr: $(BUILDER_BUILD_DIR)/$(libantlr_dir)/Makefile
	cd $(BUILDER_BUILD_DIR)/$(libantlr_dir) && PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site)  make && make install

clean-libantlr: 
	cd  $(BUILDER_BUILD_DIR)/$(libantlr_dir) && make clean

veryclean-libantlr: 
	-cd $(BUILDER_BUILD_DIR)/$(libantlr_dir) && make distclean 
	rm -f $(BUILDER_SRC_DIR)/$(libantlr_dir)/configure

clean-makefile-libantlr: 
	cd $(BUILDER_BUILD_DIR)/$(libantlr_dir) && rm -f Makefile
