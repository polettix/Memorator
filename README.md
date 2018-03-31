# NAME

Memorator - Remind of events via Minion

# VERSION

This document describes Memorator version {{\[ version \]}}.

<div>
    <a href="https://travis-ci.org/polettix/Memorator">
    <img alt="Build Status" src="https://travis-ci.org/polettix/Memorator.svg?branch=master">
    </a>
    <a href="https://www.perl.org/">
    <img alt="Perl Version" src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg">
    </a>
    <a href="https://badge.fury.io/pl/Memorator">
    <img alt="Current CPAN version" src="https://badge.fury.io/pl/Memorator.svg">
    </a>
    <a href="http://cpants.cpanauthors.org/dist/Memorator">
    <img alt="Kwalitee" src="http://cpants.cpanauthors.org/dist/Memorator.png">
    </a>
    <a href="http://www.cpantesters.org/distro/M/Memorator.html?distmat=1">
    <img alt="CPAN Testers" src="https://img.shields.io/badge/cpan-testers-blue.svg">
    </a>
    <a href="http://matrix.cpantesters.org/?dist=Memorator">
    <img alt="CPAN Testers Matrix" src="https://img.shields.io/badge/matrix-@testers-blue.svg">
    </a>
</div>

# SYNOPSIS

    use Minion;
    my $minion = Minion->new(...);

    use Memorator;
    my $memorator = Memorator->create(
       alert_callback => sub {
          my $id = shift;
          print "notification for id <$id>\n";
          return;
       }
       minion => $minion,
       name => 'memorator', # this is the default
    );

    $minion->enqueue(memorator_process_update =>
       {
          id => 'id-001',       # identifier meaningful for you
          epoch => (time + 30), # when you want the alert
          attempts => 5,        # how many retries before giving up
       }
    );

# DESCRIPTION

This module allows you to set alerts for some events you need to be warned
of. It's as simple as asking an alarm to ring at a certain date/time.

The module leverages on [Minion](https://metacpan.org/pod/Minion) for the heavylifting. It's actually
a thin API on top of it, installing two _tasks_ which by default go under
the names `memorator_process_update` and `memorator_process_alert`
(although you can change the `memorator` part using ["name"](#name)).

The interaction model is simple:

- you create an object with an ["alert\_callback"](#alert_callback) and a `minion` object
that will do the hard work. The ["alert\_callback"](#alert_callback) is where you will
implement your logic for when the alert expires;
- you enqueue _updates_ to set new alarms or modify existing ones, based on
an _identifier_ that is meaningful for you;
- at the expiration of the alarm time, the ["alert\_callback"](#alert_callback) is called with
the specific _identifier_, so that you can figure out what has to be done
next.

To add a new reminder, or change an existing one, you use
`memorator_process_update` passing a hash reference like this:

    $minion->enqueue(memorator_process_update =>
       {
          eid => 'id-001',      # identifier meaningful for you
          epoch => (time + 30), # when you want the alert
          attempts => 5,        # how many retries before giving up
       }
    );

You can also set alerts directly, without the mediation of [Minion](https://metacpan.org/pod/Minion),
using ["set\_alert"](#set_alert):

    $memorator->set_alert(\%same_hashref_as_before);

See ["set\_alert"](#set_alert) for the allowed keys.

# METHODS

## **alert\_callback**

    my $sub_reference = $obj->alert_callback;
    $obj->alert_callback(sub {...});

accessor for the callback to be run when an alert has to be sent. It is
mandatory to set this before the first alert is sent. Can be set in the
constructor.

The callback will be invoked like follows:

    $callback->($identifier);

where `$identifier` is a meaningful identifier for your applications
(which is also the identifier passed upon creation of the event).

## **minion**

    my $minion = $obj->minion;
    $obj->minion($minion_instance);

accessor for the [Minion](https://metacpan.org/pod/Minion) used behind the scenes. Note that in callbacks
called in jobs the minion instance will be drawn from the jobs themselves,
as it might prove to be _fresher_.

## **name**

    my $name = $obj->name;
    $obj->name($new_name);

accessor for a name for generating local names of tables in the database,
as well as task names in [Minion](https://metacpan.org/pod/Minion). This allows you to have more instances
living inside the same [Minion](https://metacpan.org/pod/Minion), should you ever need to do this.
Defaults to `memorator`. Can be set in the constructor.

## **new**

    my $obj = Memorator->new(%args);
    my $obj = Memorator->new(\%args);

constructor. The recognized keys in `%args` correspond to accessors
["alert\_callback"](#alert_callback) (mandatory), ["minion"](#minion) (mandatory) and ["name"](#name)
(optional).

## **set\_alert**

    $obj->set_alert(\%hashref);

Set an alert. The following keys are supported:

- `attempts`

    how many times [Minion](https://metacpan.org/pod/Minion) will retry upon failure of your callback. In this
    case, _failure_ means _thrown exception_.

- `epoch`

    the UTC epoch at which you want the alert callback to be triggered.

- `id`

    the [identifier](https://metacpan.org/pod/identifier) for your event, which can help you retrieve the details
    of your event somewhere else. It has a textual form, so you might want to
    abuse it to store more data (e.g. some JSON data); just keep in mind that
    it is treated as an _opaque identifier_, i.e. a string that is compared
    to other strings for equality.

You don't need to call this directly if you use [Minion](https://metacpan.org/pod/Minion) for enqueuing
alerts via `memorator_process_update` (or whatever name the task has,
based on ["name"](#name)).

# BUGS AND LIMITATIONS

Report bugs through GitHub (patches welcome).

# SEE ALSO

[Minion](https://metacpan.org/pod/Minion).

# AUTHOR

Flavio Poletti <polettix@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 by Flavio Poletti <polettix@cpan.org>

This module is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.
