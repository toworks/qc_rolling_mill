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

	# values, timestamp, side, heat, standard, grade, strength_class, section

	$query  = "WITH upsert AS (UPDATE temperature_current SET timestamp=EXTRACT(EPOCH FROM now()),  ";
    $query .= "heat = ?, ";
    $query .= "grade = ?, ";
	$query .= "strength_class = ?, ";
    $query .= "section = ?, ";
    $query .= "standard = ?, ";
    $query .= "temperature = ? ";
    $query .= "WHERE tid = ? and side = ? RETURNING *) ";
	
    $query .= "INSERT INTO temperature_current (tid, timestamp, heat, grade, ";
	$query .= "strength_class, section, standard, side, temperature) ";
	$query .= "SELECT ?, EXTRACT(EPOCH FROM now()), ?, ?, ";
	$query .= "?, ?, ?, ?, ? ";
    $query .= "WHERE NOT EXISTS (SELECT * FROM upsert) ";
	  
	$self->{log}->save('d', "values: " . join(" | ", @values)) if $self->{sql}->{'DEBUG'};
	$self->{log}->save('d', "query: ". $query) if $self->{sql}->{'DEBUG'};

	eval{ 		$self->{sql}->{dbh}->{RaiseError} = 1;
				$self->{sql}->{dbh}->{AutoCommit} = 0;
				$sth = $self->{sql}->{dbh}->prepare_cached($query) || die $self->{sql}->{dbh}->errstr;
				foreach ( @values ) {
					$_->[7] =~ s/.*?([\d+\.].*)/$1/;
					# fixed size in section
					$_->[7] = ($_->[7] !~ /\./g and scalar $_->[7] > 2) ? substr($_->[7], 0, 2) : $_->[7];
					print "values: ", $_->[7], "\n";

					use Encode;
					$sth->bind_param(  1, $_->[3] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  2, decode('cp1251', $_->[5]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  3, decode('cp1251', $_->[6]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  4, $_->[7] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  5, decode('cp1251', $_->[4]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  6, int($_->[0]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  7, $_->[1] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param(  8, $_->[2] ) || die $self->{sql}->{dbh}->errstr;

					$sth->bind_param(  9, $_->[1] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 10, $_->[3] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 11, decode('cp1251', $_->[5]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 12, decode('cp1251', $_->[6]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 13, $_->[7] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 14, decode('cp1251', $_->[4]) ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 15, $_->[2] ) || die $self->{sql}->{dbh}->errstr;
					$sth->bind_param( 16, int($_->[0]) ) || die $self->{sql}->{dbh}->errstr;

					$sth->execute() || die $self->{sql}->{dbh}->errstr;
				}
				#$sth->execute() || die $self->{sql}->{dbh}->errstr;
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
