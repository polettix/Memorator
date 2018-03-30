package Memorator;
use strict;
use warnings;
{ our $VERSION = '0.001'; }

use Mojo::Base -base;
use Try::Tiny;

use constant ATTEMPTS       => 2;                  # default value
use constant TABLE_NAME     => 'eid2jid';
use constant PROCESS_ALERT  => 'process_alert';
use constant PROCESS_UPDATE => 'process_update';

has alert_callback => sub { die 'missing mandatory parameter "alert_cb"' };
has name => 'memorator';

sub add_tasks {
   my ($self, $minion) = @_;
   $minion->add_task($self->local_name(PROCESS_UPDATE) =>
        sub { $self->_process_update(@_) });
   $minion->add_task(
      $self->local_name(PROCESS_ALERT) => sub { $self->_process_alert(@_) }
   );
   return $self;
} ## end sub add_tasks

sub _cleanup_alerts {
   my ($self, $minion) = @_;

   my $dbh   = __minion2db($minion)->db;    # go to lower level
   my $table = $self->local_name(TABLE_NAME);
   my $log   = $minion->app->log;

   my $res = try {
      $dbh->query(<<"END");
SELECT * FROM $table
   WHERE (id, eid) NOT IN (SELECT MAX(id), eid FROM $table GROUP BY eid)
END
   } ## end try
   catch {
      $log->error("$table cleanup error: $_");
   };
   return unless $res;

   while (my $href = $res->hash) {
      my ($id, $eid, $jid) = @{$href}{qw< id eid jid >};
      try {
         $log->info("removing superseded job '$jid'");
         if (my $job = $minion->job($jid)) {
            $job->remove
              if $job->info->{state} =~ m{\A(?: active | inactive )\z}mxs;
         }
         $dbh->query("DELETE FROM $table WHERE id = ?", $id);
      } ## end try
      catch {
         $log->error("$table cleanup of id<$id>/eid<$eid>/jid<$jid> "
              . "error: $_");
      };
   } ## end while (my $href = $res->hash)

   return;
} ## end sub _cleanup_alerts

sub ensure_table {
   my ($self, $minion) = @_;
   my $mdb   = __minion2db($minion);
   my $table = $self->local_name(TABLE_NAME);
   $mdb->migrations->name($self->name)->from_string(<<"END")->migrate;
-- 1 up
CREATE TABLE IF NOT EXISTS $table (
   id  INTEGER PRIMARY KEY AUTOINCREMENT,
   eid INTEGER,
   jid INTEGER,
   active INTEGER DEFAULT 1
);
-- 1 down
DROP TABLE $table;
END
   return $self;
} ## end sub ensure_table

sub initialize {
   my ($self, $minion) = @_;
   return $self->ensure_table($minion)->add_tasks($minion);
}

sub local_name {
   my ($self, $suffix) = @_;
   (my $retval = $self->name . '_' . $suffix) =~ s{\W}{_}gmxs;
   return $retval;
}

sub __minion2db {
   my ($minion) = @_;
   my $backend = $minion->backend;
   (my $dbtech = ref $backend) =~ s{.*::}{}mxs;
   return $backend->can(lc($dbtech))->($backend);
} ## end sub __minion2db

sub _process_alert {
   my ($self, $job, $eid) = @_;

   my $dbh   = __minion2db($job->minion)->db;    # go to lower level
   my $table = $self->local_name(TABLE_NAME);

   my $jid = $job->id;
   my $res = $dbh->query(<<"END", $jid, $eid, $jid);
SELECT * FROM $table
   WHERE  jid = ? AND eid = ? AND active > 0
      AND id IN (SELECT MAX(id) FROM $table WHERE jid = ?)
END
   my $e2j = $res->hash;
   $res->finish;
   return $job->fail unless $e2j;

   # this job is entitled to send the alert for this external identifier
   $self->alert_callback->($eid);

   # now passivate it
   $dbh->query("UPDATE $table SET active = 0 WHERE id = ?", $e2j->{id});
   $self->_cleanup_alerts($job->minion);

   return;
} ## end sub _process_alert

sub _process_update {
   my ($self, $job,   $alert)    = @_;
   my ($eid,  $epoch, $attempts) = @{$alert}{qw< eid epoch attempts >};
   $attempts //= ATTEMPTS;

   my $minion = $job->minion;
   my $dbh    = __minion2db($minion)->db;      # go to lower level
   my $table  = $self->local_name(TABLE_NAME);
   my $task   = $self->local_name(PROCESS_ALERT);
   my $log    = $minion->app->log;

   my $now = time;
   my $delay = ($epoch > $now) ? ($epoch - $now) : 0;

   $log->debug("enqueuing $task in $delay s");
   my $jid = $job->minion->enqueue(
      $task => [$eid],
      {delay => $delay, attempts => $attempts}
   );

   # record for future mapping and cleanup stuff
   my $res = $dbh->insert($table => {eid => $eid, jid => $jid});
   $self->cleanup_alerts($minion); # never fails

   return;
} ## end sub process_update

1;
