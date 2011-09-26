# bcbiff

## NAME

`bcbiff(1) - Boxcar based IMAP biff`

## SYNOPSIS

`bcbiff`

## DESCRIPTION

Bcbiff checks the Inbox folder on an IMAP server for unread mails and
sends a notification for each.

This tool was made to send push notification to your iPhone via Boxcar
when you have received a mail in Inbox on an IMAP server, primarily
with Gmail in mind.  Bcbiff composes a notification mail that has
From, Date and Subject header fields copied from the original, with
other fields and the body part removed.

Simple mail forwarding using a filter on Gmail has a couple of
problems.  First, there is no easy way to write a filter that only
matches mails that will be dropping in Inbox.  Second, mail bodies and
sensitive header fields will be leaked.  Bcbiff solves both.

## FILES

* `~/.bcbiff`

    User configuration file that would look like below.

        ---
        :accounts:
        - :host: imap.gmail.com
          :port: 993
          :ssl: true
          :username: "account1"
          :password: "********"
          :mailto: "******.*******@push.boxcar.io"
        - :host: imap.gmail.com
          :port: 993
          :ssl: true
          :username: "account2@your.domain"
          :password: "********"
          :mailto: "******.*******@push.boxcar.io"

## USAGE

Prepare your `~/.bcbiff`, adjust constants defined in `bcbiff` for
your system and run bcbiff once a minute or so.

## REQUIREMENTS

Bcbiff will run with Ruby 1.8.7+ and 1.9.2+.

See `Gemfile` for dependency.  Run `bundle install` to install what's
missing.

Bcbiff calls the `sendmail` command to send a mail.  Sendmail (or any
compatible software such as Qmail or Postfix) must be properly
configured.

## SEE ALSO

* [Boxcar](http://boxcar.io/)

* [Gmail](https://mail.google.com/)

## AUTHOR

Copyright (c) 2011 Akinori MUSHA.

Licensed under the 2-clause BSD license.  See `LICENSE.txt` for
details.

Visit [GitHub Repository](https://github.com/knu/bcbiff) for the
latest information.
