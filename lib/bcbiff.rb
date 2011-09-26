#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
#
# bcbiff(1) - Boxcar based IMAP biff
#
# Copyright (c) 2011 Akinori MUSHA
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

require 'rubygems'
require 'net/imap'
require 'yaml'
require 'mail'
require 'shellwords'

BCBIFF_VERSION = '0.1.3'

CERTS_PATHS   = [
  '/etc/ssl/cert.pem',		# FreeBSD
  '/etc/ssl/certs',		# Ubuntu
  '/usr/share/ssl/certs',	# RHEL4
  '/etc/pki/tls/certs',		# RHEL5
  '/opt/local/share/curl/curl-ca-bundle.crt',	# OS X; MacPorts
]
CERTS_PATH   = CERTS_PATHS.find { |f| File.exist?(f) }
IDCACHE_FILE = '~/Maildir/idcache.%s.yml'
IDCACHE_SIZE = 100
BCBIFF_FILE  = '~/.bcbiff'

def main(argv)
  accounts = config[:accounts]

  if !certs_path
    STDERR.print <<-EOS
The system path for SSL certificates is not found.
Add `:certs_path: /path/to/certs` to #{BCBIFF_FILE} or install
SSL certificates in one of the following locations:
    EOS
    CERTS_PATHS.each { |path|
      STDERR.puts "\t#{path}"
    }
    exit 1
  end

  accounts.each { |options|
    check_mails(options)
  }
end

def config
  $config ||=
    begin
      value = YAML.load_file(File.expand_path(BCBIFF_FILE))
      raise unless value.is_a?(Hash) && value.key?(:accounts)
      value
    end
rescue
  STDERR.puts "Put your configuration in #{BCBIFF_FILE} that looks like below.", ''
  STDERR.print YAML.dump({
    :accounts => [
        {
          :host => 'imap.gmail.com',
          :port => 993,
          :ssl  => true,
          :username => 'your.account',
          :password => 'password1',
          :mailto => 'dead.beef@push.boxcar.io',
        },
        {
          :host => 'imap.gmail.com',
          :port => 993,
          :ssl  => true,
          :username => 'you@your.domain',
          :password => 'password2',
          :mailto => 'feed.babe@push.boxcar.io',
          :folders => %w[Inbox work/important],
        }
    ]
  })
  exit 1
end

def certs_path
  $certs_path ||= config[:certs_path] || CERTS_PATH
end

def check_mails(options)
  #Net::IMAP.debug = true
  mailto = options[:mailto]
  msgids_file = File.expand_path(IDCACHE_FILE % mailto)

  File.open(msgids_file, File::RDWR | File::CREAT, 0600) {|f|
    f.flock(File::LOCK_EX | File::LOCK_NB) or break

    imap = Net::IMAP.new(options[:host], options[:port], options[:ssl], certs_path, true)
    imap.login(options[:username], options[:password])
    folders = options[:folders] || ['Inbox']
    unseen = folders.inject([]) { |unseen, folder|
      imap.select(folder)
      unseen.concat(imap.search('UNSEEN'))
    }
    return if unseen.empty?

    msgids = YAML.load(f) || []

    imap.fetch(unseen, item = 'RFC822.HEADER').each { |data|
      mail = Mail.read_from_string(data.attr[item])
      msgid = mail.message_id
      next if msgids.include?(msgid)
      msgids << msgid

      (header = mail.header).fields.each { |field|
        case name = field.name
        when /\A(From|Subject|Date)\z/i
          # preserve
        else
          header[name] = nil
        end
      }

      open("| sendmail #{mailto.shellescape}", 'w') { |sendmail|
        sendmail.print mail.encoded
      }
    }
    msgids.slice!(0...-IDCACHE_SIZE) if msgids.size > IDCACHE_SIZE

    f.rewind
    f.print YAML.dump(msgids)
    f.truncate(f.pos)
  }
end

main(ARGV) if $0 == __FILE__
