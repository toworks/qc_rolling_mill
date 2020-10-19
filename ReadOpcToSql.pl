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
 use cache;
 use _opc;
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

 # create object
 my $sql_write = _sql->new($log);
 $sql_write->set('DEBUG' => $DEBUG);
 $sql_write->set('type' => $conf->get('write')->{sql}->{type});
 $sql_write->set_con(	$conf->get('write')->{sql}->{'driver'},
						$conf->get('write')->{sql}->{'host'},
						$conf->get('write')->{sql}->{'database'},
					);
 $sql_write->set('user' => $conf->get('write')->{sql}->{'user'});
 $sql_write->set('password' => $conf->get('write')->{sql}->{'password'});
 $sql_write->set('dialect' => $conf->get('write')->{sql}->{'dialect'});
 $sql_write->set('table' => $conf->get('write')->{sql}->{'table'});

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

	# opc create object
	my $opc = _opc->new($log);
	$opc->set('DEBUG' => $DEBUG);
	$opc->set('progid' => $conf->get('opc')->{progid});
	$opc->set('name' => $conf->get('opc')->{name});
	$opc->set('host' => $conf->get('opc')->{host});
	$opc->set('groups' => $conf->get('groups'));

	while (1) {

		my $t0 = [gettimeofday];

		my $cache = cache->new($log, $log->get_name().'.cache.yml');		

		$opc->connect() if $opc->get('error') == 1;

		my $values = $opc->read('read');
		
		my $sql_values = $sql_read->get_fb_melt();
		
		my @values;

		foreach my $index ( keys @{$values} ) {
			my $tag_name = $conf->get('groups')->{read}->[$index];
			my $side = $conf->get('values')->{$tag_name}->{side_int};
#=comm
			foreach my $i ( keys @{$sql_values} ) {
#				print "sql index: ", $i, "\n";
				if ( defined($sql_values->[$i]->{SIDE}) and defined($side) and $sql_values->[$i]->{SIDE} eq $side ) {
					print "sql index: ", $i, "\n" if $DEBUG;
					print "---------------\n", Dumper($sql_values->[$i]), "---------------\n" if $DEBUG;
					my ($day,$month,$year,$hours,$min,$sec) = split('[:\s\.]', $sql_values->[$i]->{TN});
					use Time::Local;
					my $timestamp = timelocal($sec,$min,$hours,$day,$month,$year);
					#print $sec,$min,$hours,$day,$month,$year, $time,"--\n";
					push @values, [	$values->[$index], $timestamp, $sql_values->[$i]->{SIDE}, $sql_values->[$i]->{HEAT},
									$sql_values->[$i]->{STANDARD}, $sql_values->[$i]->{GRADE}, $sql_values->[$i]->{STRENGTH_CLASS},
									$sql_values->[$i]->{SECTION}];
				}
			}
#=cut
			print "opc index:", $index ," | ", $tag_name, " | side: ", $side, " | value: ", $values->[$index], "\n" if $DEBUG;
		}
		
		#print Dumper($sql_read->get_fb_melt());
		#print Dumper($sql_write->get_pg());

		#print Dumper(@values);
		$sql_write->write_pg(@values);

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
