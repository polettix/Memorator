# NAME

Memorator - \[ a brief description of the distribution \]

# VERSION

This document describes Memorator version {{\[ version \]}}.

# SYNOPSIS

    use Memorator;

# DESCRIPTION

This module allows you to...

# FUNCTIONS

## **whatever**

# METHODS

## **add\_tasks**

    my $obj_itself = $obj->add_tasks($minion);

add tasks to [Minion](https://metacpan.org/pod/Minion) for processing incoming updates and firing up
alerts. The name of the added tasks is generated using ["local\_name"](#local_name) over
strings `process_alert` and `process_update`.

Returns the invoking object.

It is called automatically by ["initialize"](#initialize).

## **alert\_callback**

    my $sub_reference = $obj->alert_callback;
    $obj->alert_callback(sub {...});

accessor for the callback to be run when an alert has to be sent. It is
mandatory to set this before the first alert is sent. Can be set in the
constructor.

## **ensure\_table**

    my $obj_itself = $obj->ensure_table($minion);

ensure that there are the needed tables in the same database as
`$minion`. Support for different backends might need some tweaking over
time because of differences in how to define tables in different database
technologies, please report any deficiencies in this area. In initial
releases, it should be compatible with SQLite and Postgresql.

## **initialize**

    my $obj_itself = $obj->initialize($minion);

initialize an instance attaching to a [Minion](https://metacpan.org/pod/Minion). This method makes sure to
create the needed tables via ["ensure\_table"](#ensure_table) and to register tasks in
`$minion` using ["add\_tasks"](#add_tasks).

Returns the invoking object.

## **local\_name**

    my $ln = $obj->local_name($suffix);

generate a _local name_ by joining ["name"](#name) and the provided `$suffix`
with an underscore character, then turning all non-word characters in the
result to underscores. For example, if ["name"](#name) is `What-Ever` and the
provided `$suffix` is `you do`, the result would be `What_Ever_you_do`.

It is also used to generate the name of the table for mappings, by
localizing name `eid2jid` (which stands for _external identifier to job
identifier_).

## **name**

    my $name = $obj->name;
    $obj->name($new_name);

accessor for a name for generating local names with ["local\_name"](#local_name). This
allows you to have more instances living inside the same [Minion](https://metacpan.org/pod/Minion), should
you ever need to do this. Defaults to `memorator`. Can be set in the
constructor.

# BUGS AND LIMITATIONS

Report bugs through GitHub (patches welcome).

# SEE ALSO

Foo::Bar.

# AUTHOR

Flavio Poletti <polettix@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 by Flavio Poletti <polettix@cpan.org>

This module is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.
