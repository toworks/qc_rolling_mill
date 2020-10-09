#!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;
 use threads;
 use threads::shared;
 use Thread::Queue;
 use DateTime;
 use Time::HiRes qw(gettimeofday tv_interval time);
 use POSIX qw(strftime);
 use LWP::UserAgent;
 use lib ('libs', '.');
 use logging;
 use configuration;
 use _sql;

 my $DEBUG: shared;

 $| = 1;  # make unbuffered

 my $VERSION = "0.1 (20201007)";
 my $log = LOG->new();
 my $conf = configuration->new($log);

 $log->save('i', "program version: ".$VERSION);
 
 $DEBUG = $conf->get('app')->{'debug'};

 # create object
 my $sql_read = _sql->new($log);
 $sql_read->set('DEBUG' => $DEBUG);
 $sql_read->set('type' => $conf->get('read')->{sql}->{type});
 $sql_read->set_con(	$conf->get('read')->{sql}->{'driver'},
						$conf->get('read')->{sql}->{'host'},
						$conf->get('read')->{sql}->{'database'},
					);
 $sql_read->set('user' => $conf->get('read')->{sql}->{'user'});
 $sql_read->set('password' => $conf->get('read')->{sql}->{'password'});
 $sql_read->set('dialect' => $conf->get('read')->{sql}->{'dialect'});
 $sql_read->set('table' => $conf->get('read')->{sql}->{'table'});

 my $queue = Thread::Queue->new();

 my @threads;
 for ( 1..$conf->get('app')->{'tasks'} ) {
	push @threads, threads->create( \&worker, $conf, $log, $sql_read);
 }

## $SIG{'TERM'} = $SIG{'HUP'} = $SIG{'INT'} = sub {
##                      local $SIG{'TERM'} = 'IGNORE';
###						$log->save('d', "SIGNAL TERM | HUP | INT | $$");
##					  $log->save('i', "stop app");
##                      kill TERM => -$$;
## };

 # main
 threads->new(\&main, $$, $conf, $log);

 # main loop
 {
   $log->save('i', "start main loop");

   while (threads->list()) {
#        $log->save('d', "thread main");
	   sleep(1);
	   #select undef, undef, undef, 1;
       if ( ! threads->list(threads::running) ) {
#            $daemon->remove_pid();
           $SIG{'TERM'} = 'DEFAULT'; # Восстановить стандартный обработчик
           kill TERM => -$$;
		   $log->save('i', "PID $$");
        }
    }
  }

 
 
 sub main {
    my($id, $conf, $log) = @_;
  
	$log->save('i', "start thread pid $id");

	while (1) {

		my $t0 = [gettimeofday];
		
		print Dumper($sql_read->get_fb_melt());
=comm
		my $message;

		for ( my $i = 0 ; $i < scalar @{$conf->get('devices')} ; $i++ ) {
			if ( $conf->get('devices')->[$i]->{'enable'} ) {
				$message = http_request(	$conf->get('service')->{'url'} .
											$conf->get('devices')->[$i]->{'service_preffix'} .
											"?deviceId=" .
											$conf->get('devices')->[$i]->{'deviceId'} .
											"&apitoken=" .
											$conf->get('service')->{'api_token'}
											, $ua
										);

				next if not defined $message;
				my $value = 1 if $message->{'state'}->{'type'} eq $conf->get('devices')->[$i]->{'state_work'};
				print Dumper($message->{'state'}->{'type'}), "\n" if $message->{'state'}->{'type'} eq $conf->get('devices')->[$i]->{'state_work'};
				#print $message->{'state'}->{'type'}, " | " , $type, "\n";
				#print Dumper($message), "\n";
				#print Dumper($conf->get('devices')->[$i]->{'state_work'}), "\n";
				$queue->enqueue( [$i, $value || 0] );
			}
		}
=cut	
		my $t1 = [gettimeofday];
		my $tbetween = tv_interval $t0, $t1;
		my $cycle;
		if ( $tbetween < $conf->get('app')->{'cycle'} ) {
			$cycle = $conf->get('app')->{'cycle'} - $tbetween;
		} else {
			$cycle = 0;
		}

		$log->save('d', "cycle:  setting: ". $conf->get('app')->{'cycle'} ."  current: ". $cycle) if $DEBUG;
        print "cycle:  setting: ", $conf->get('app')->{'cycle'}, "  current: ", $cycle, "\n" if $DEBUG;
        select undef, undef, undef, $cycle;

	}
  }


 sub http_request {
	my ($url, $ua) = @_;
	$log->save("i", "$url") if $DEBUG;

	my $req = HTTP::Request->new(GET => "$url") || die $@;
	$req->content_type('application/json; charset=utf-8');
	#$req->content($action);
	my $message;
	
	eval {			 
			# Pass request to the user agent and get a response back
			my $res = $ua->request($req);

			#$log->save("d", "http_request: ". Dumper($res) ) if $DEBUG;

			# Check the outcome of the response
			if ($res->is_success) {
				print $res->content,"\n" if $DEBUG;
				use Encode;
				$message = decode('utf-8', $res->content);
				use JSON;
				my $json = JSON->new->allow_nonref;
				$message = $json->decode( $message );
				$log->save("d", "http_request: ". Dumper($message) ) if $DEBUG;
			}
			else {
				#print Dumper($res->headers), "\n";
				#print Dumper($res->headers->{'location'}), "\n";
				#print $res->status_line, "\n";
				#$log->save("e", "status: " . $res->status_line);
				die "status: " . $res->status_line;
			}
	};
	if ($@) { $log->save("e", "$@"); };
	return $message;
 }

 sub worker {
    my($conf, $log, $sql) = @_;
    $log->save('i', "start worker thread id ".threads->self()->tid());
=comm
	# mssql create object
	my $sql = _sql->new($log);
	$sql->set('DEBUG' => $DEBUG);
	$sql->set('type' => $conf->get('sql')->{type});
	$sql->set_con(	$conf->get('sql')->{'driver'},
					$conf->get('sql')->{'host'},
					$conf->get('sql')->{'database'}	);
	$sql->set('table' => $conf->get('sql')->{'table'});
=cut
	while ( my $job = $queue->dequeue() ) {
		my $index = $job->[0];
		shift @{$job};
		unshift @{$job}, $conf->get('devices')->[$index]->{'short_id'};
		push @{$job}, $conf->get('devices')->[$index]->{'id_measuring'};
		$log->save('d', "unshift: ". Dumper(\@{$job})) if $DEBUG;
		$sql->write(@{$job});
	}
 }
