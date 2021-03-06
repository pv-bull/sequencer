# -*- coding: utf-8 -*-
###############################################################################
# Copyright (C) Bull S.A.S (2010, 2011)
# Contributor: Pierre Vignéras <pierre.vigneras@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
###############################################################################
current_makefile := $(lastword $(MAKEFILE_LIST))

# TODO: Here, you list all the files and directories you want to include
# with your release. When a directory is specified, all its content is
# taken into account recursively.
files := conf bin lib doc setup.py MANIFEST.in README COPYING HOWTO

man_files_core := sequencer.dgmdb.1 sequencer.1 sequencer.graphrules.1 sequencer.knowntypes.1 sequencer.depmake.1 sequencer.seqmake.1 sequencer.seqmake.5 sequencer.seqexec.1 sequencer.seqexec.5 sequencer.chain.1
man_alias := graphrules.1 knowntypes.1 depmake.1 seqmake.1 seqmake.5 seqexec.1 seqexec.5 chain.1 dgmdb.1
man_files := $(man_files_core) $(man_alias)

name := sequencer
version := $(shell grep '^version=.*' ./VERSION|sed 's/^version=//g')
lastcommit := $(shell git log --pretty=format:'%H %aN %aE %ci'  -1)
pkg_dir := $(name)-$(version)
tarall := $(pkg_dir).tar.gz
package_name := $(pkg_dir)-$(release)
tmpdir := $(shell mktemp -d)

# Default target: erase only produced files.
clean:
	rm -f *~ archives/$(tarall) archives/$(tarall)

# Use this target to get information gathered by this Makefile.
# 'make config'
config:
	@echo "name:		$(name)"
	@echo "pkg_dir:		$(pkg_dir)"
	@echo "tarall:		$(tarall)"
	@echo "tmpdir:		$(tmpdir)"
	@echo "version:		$(version)"
	@echo "tag:		$(tagname)"
	@echo "INFO: config OK"
        @echo "tarall: $(tarall)"

# Copy required source files to a temporary directory. This directory
# will be tarred. The tar file will then be used by the rpmbuild
# command.
mkdir: config
	mkdir -p archives
	mkdir -p $(tmpdir)/$(pkg_dir)

copy: mkdir doc
	cp -r $(files) $(tmpdir)/$(pkg_dir)

# Create the ChangeLog file and add changelog entries to the RPM .spec file.
log: copy
	git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n" > $(tmpdir)/$(pkg_dir)/doc/ChangeLog

version: copy
	@echo "# The content of this file is generated by the packaging" >  $(tmpdir)/$(pkg_dir)/lib/$(name)/.metainfo
	@echo "# process (either setup.py or Makefile)" >> $(tmpdir)/$(pkg_dir)/lib/$(name)/.metainfo
	@echo "# Do not change it manually." >> $(tmpdir)/$(pkg_dir)/lib/$(name)/.metainfo
	@echo "$(name).version = $(version)" >> $(tmpdir)/$(pkg_dir)/lib/$(name)/.metainfo
	@echo "$(name).lastcommit = $(lastcommit)" >> $(tmpdir)/$(pkg_dir)/lib/$(name)/.metainfo

man: copy
	@for i in $(man_files);do \
		gzip -c doc/man/$$i > $(tmpdir)/$(pkg_dir)/doc/man/$$i.gz; \
	done

pdfman:
	@echo pdf man pages are generated in /tmp
	@for i in $(man_files_core);do \
		groff -Tps -man doc/$$i |ps2pdf - /tmp/$$i.pdf ; \
	done

tar: version man
	tar --exclude-vcs --exclude '*~' --exclude '#*#' -C $(tmpdir) --owner=root --group=root -cvzf archives/$(tarall) $(pkg_dir)
	@echo "INFO: tar OK"

test:
	@echo "*****************************************************************************"
	@echo "*****************************************************************************"
	@echo "*** Test requires some configuration to work! Please see the HOWTO file.  ***"
	@echo "*****************************************************************************"
	@echo "*****************************************************************************"
	@nosetests

coverage:
	@nosetests --with-coverage --cover-html --cover-html-dir=unpackaged/tests-report/ --cover-package=$(name)

pylint:
	@PYTHONPATH=${PYTHONPATH}:lib pylint -i y -r n -f colorized --rcfile=unpackaged/pylint.rc $(name) bin/$(name)

sloc:
	@sloccount --wide  lib tests bin

tag: test
	@unpackaged/tools/autotag VERSION

release: tag
	@unpackaged/tools/ask4release .


