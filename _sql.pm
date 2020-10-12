package _sql;{
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  #use parent -norequire, 'sql';
  use parent "sql";
  use DBI qw(:sql_types);
  use Data::Dumper;

  sub get_fb_melt {
    my($self, @values) = @_;
    my($sth, $ref, $query);

    $self->conn() if ( $self->{sql}->{error} == 1 or ! $self->{sql}->{dbh}->ping );

	$query  = "select t1.begindt as tn, t1.NOPLAV as heat, t1.MARKA as grade, t1.KLASS ";
	$query .= "as strength_class, t1.RAZM1 as section, t1.STANDART as standard, t1.SIDE FROM $self->{sql}->{table} t1, ";
	$query .= "(select max(begindt) max_begindt, SIDE from $self->{sql}->{table} where state = 1 group by side) t2 ";
	$query .= "where t2.max_begindt = t1.begindt ";
	  
	$self->{log}->save('d', "values: " . join(" | ", @values)) if $self->{sql}->{'DEBUG'};
	$self->{log}->save('d', "query: ". $query) if $self->{sql}->{'DEBUG'};

	eval{ 		$self->{sql}->{dbh}->{RaiseError} = 1;
				#$self->{sql}->{dbh}->{AutoCommit} = 0;
				$sth = $self->{sql}->{dbh}->prepare_cached($query) || die $self->{sql}->{dbh}->errstr;
				$sth->execute() || die $self->{sql}->{dbh}->errstr;
				#$self->{sql}->{dbh}->{AutoCommit} = 1;
	};
	if ($@) {   $self->set('error' => 1);
				$self->{log}->save('e', "$@");
	}
    unless($@) {
        eval{
				my $count = 0;
				#print Dumper($sth->fetchrow_hashref());
                while ($ref = $sth->fetchrow_hashref()) {
					#print Dumper($ref), "\n";
					$values[$count] = $ref;
					$count++;
#					print Dumper(@values), "\n";
#					print $#values, "\n";
                }
        }
    }
    eval{ $sth->finish() || die "$DBI::errstr";	};
    if ($@) {   $self->set('error' => 1);
                $self->{log}->save('e', "$DBI::errstr");
    };

	$self->{log}->save('d', "sql 'get_fb_melt' values count: ". $#values) if $self->{'sql'}->{'DEBUG'};
    #$self->{log}->save('d', "\n".Dumper(\@values)."\n") if $self->{'sql'}->{'DEBUG'};

    return(\@values);
 }
 
 sub get_pg {
    my($self, @values) = @_;
    my($sth, $ref, $query);

    $self->conn() if ( $self->{sql}->{error} == 1 or ! $self->{sql}->{dbh}->ping );

	$query  = "select * from $self->{sql}->{table} limit 2 ";
	  
	$self->{log}->save('d', "values: " . join(" | ", @values)) if $self->{sql}->{'DEBUG'};
	$self->{log}->save('d', "query: ". $query) if $self->{sql}->{'DEBUG'};

	eval{ 		$self->{sql}->{dbh}->{RaiseError} = 1;
				#$self->{sql}->{dbh}->{AutoCommit} = 0;
				$sth = $self->{sql}->{dbh}->prepare_cached($query) || die $self->{sql}->{dbh}->errstr;
				$sth->execute() || die $self->{sql}->{dbh}->errstr;
				#$self->{sql}->{dbh}->{AutoCommit} = 1;
	};
	if ($@) {   $self->set('error' => 1);
				$self->{log}->save('e', "$@");
	}
    unless($@) {
        eval{
				my $count = 0;
				#print Dumper($sth->fetchrow_hashref());
                while ($ref = $sth->fetchrow_hashref()) {
					#print Dumper($ref), "\n";
					$values[$count] = $ref;
					$count++;
#					print Dumper(@values), "\n";
#					print $#values, "\n";
                }
        }
    }
    eval{ $sth->finish() || die "$DBI::errstr";	};
    if ($@) {   $self->set('error' => 1);
                $self->{log}->save('e', "$DBI::errstr");
    };

	$self->{log}->save('d', "sql 'get_fb_melt' values count: ". $#values) if $self->{'sql'}->{'DEBUG'};
    #$self->{log}->save('d', "\n".Dumper(\@values)."\n") if $self->{'sql'}->{'DEBUG'};

    return(\@values);
 }

sub write_pg {
    my($self, @values) = @_;
    my($sth, $ref, $query);

    $self->conn() if ( $self->{sql}->{error} == 1 or ! $self->{sql}->{dbh}->ping );

	$query  = "WITH upsert AS (UPDATE temperature_current SET timestamp=EXTRACT(EPOCH FROM now()),  ";
=comm
    $query .= "heat='''+main.Heat+''', ";
    $query .= "grade='''+main.Grade+''', ";
	$query .= "strength_class='''+main.StrengthClass+''', ";
    $query .= "section='+main.Section+', ";
    $query .= "standard='''+main.Standard+''', ";
    $query .= "temperature='+inttostr(InTemperature)+' ";
    $query .= "WHERE tid='+tid+' and side='+inttostr(InSide)+' RETURNING *) ";
#    $query .= "INSERT INTO temperature_current (tid,timestamp,heat,grade, ";
#	$query .= "strength_class,section,standard,side,temperature) ";
#	$query .= "SELECT '+tid+', EXTRACT(EPOCH FROM now()), ";
#	$query .= "'''+main.Heat+''', ";
#	$query .= "''+main.Grade+''', ";
#	$query .= "'''+main.StrengthClass+''', ";
#	$query .= "'+main.Section+', ";
#	$query .= "'''+main.Standard+''', ";
#    $query .= "'+inttostr(InSide)+', ";
#	$query .= "'+inttostr(InTemperature)+' ";
#    $query .= "WHERE NOT EXISTS (SELECT * FROM upsert) ";
=cut
	  
	$self->{log}->save('d', "values: " . join(" | ", @values)) if $self->{sql}->{'DEBUG'};
	$self->{log}->save('d', "query: ". $query) if $self->{sql}->{'DEBUG'};

	eval{ 		$self->{sql}->{dbh}->{RaiseError} = 1;
				$self->{sql}->{dbh}->{AutoCommit} = 0;
				$sth = $self->{sql}->{dbh}->prepare_cached($query) || die $self->{sql}->{dbh}->errstr;
				$sth->execute() || die $self->{sql}->{dbh}->errstr;
				$self->{sql}->{dbh}->{AutoCommit} = 1;
	};
	if ($@) {   $self->set('error' => 1);
				$self->{log}->save('e', "$@");
	}
    eval{ $sth->finish() || die "$DBI::errstr";	};
    if ($@) {   $self->set('error' => 1);
                $self->{log}->save('e', "$DBI::errstr");
    };

	$self->{log}->save('d', "sql 'get_fb_melt' values count: ". $#values) if $self->{'sql'}->{'DEBUG'};
    #$self->{log}->save('d', "\n".Dumper(\@values)."\n") if $self->{'sql'}->{'DEBUG'};

    return(\@values);
 }
}
1;
