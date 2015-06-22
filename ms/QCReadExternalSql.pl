#!D:\bin\perl\perl\bin\perl.exe


package LOG;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use open(':encoding(utf8)');
  use File::Basename;
  use Data::Dumper;
  use Time::HiRes qw(time);
  use POSIX qw(strftime);

  sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
#	  filename => basename($0).".log",
	  filename => get_name().".log",
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
	
	#$self->set_log;

    return $self;
  }

  sub get_name {
	my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );
#	print "NAME=$name\n";
#	print "PATH=$path\n";
#	print "SFFX=$suffix\n";
	return $name;
  }

=pod
Type	Level	Description
0		ALL		All levels including custom levels.
1		DEBUG	Designates fine-grained informational events that are most useful to debug an application.
2		ERROR	Designates error events that might still allow the application to continue running.
3		FATAL	Designates very severe error events that will presumably lead the application to abort.
4		INFO	Designates informational messages that highlight the progress of the application at coarse-grained level.
5		OFF		The highest possible rank and is intended to turn off logging.
6		TRACE	Designates finer-grained informational events than the DEBUG.
7		WARN	Designates potentially harmful situations.
=cut

  sub save {
    my($self, $type, $log) = @_; # ссылка на объект

	my $level;
	
	if ($type eq 0) {
		$level = 'ALL';
	} elsif ($type eq 1) {
		$level = 'DEBUG';
	} elsif ($type eq 2) {
		$level = 'ERROR';
	} elsif ($type eq 3) {
		$level = 'FATAL';
	} elsif ($type eq 4) {
		$level = 'INFO';
	} elsif ($type eq 5) {
		$level = 'OFF';
	} elsif ($type eq 6) {
		$level = 'TRACE';
	} elsif ($type eq 7) {
		$level = 'WARN';
	} else {
		$level = 'INFO';
	}
	
	unless($log) { $log = ''; }

	my $t = time;
	my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
	$date .= sprintf ".%03d", ($t-int($t))*1000;

	open(my $fh, '>>', $self->{filename}) or die "Не могу открыть файл '$self->{filename}' $!";
	print $fh "$date $level\t$log\n";
	close $fh;
  }
}
1;


package CONF;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use open(':encoding(utf8)');
  use YAML::XS qw/LoadFile/;

  sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'log' => LOG->new(),
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
	
	$self->set_conf;

    return $self;
  }

  sub set_conf {
    my($self) = @_; # ссылка на объект

	my $config = LoadFile('configuration.yml');
	
	for (keys %{$config}) {

		if ($_ =~ /mssql/){
			$self->{$_}->{host} = $config->{$_}->{host};
			$self->{$_}->{database} = $config->{$_}->{database};
			#$self->{$name}->{username} = $config->{$name}->{username};
			#$self->{$name}->{password} = $config->{$name}->{password};
		}

		if ($_ =~ /rm/){
			$self->{$_}->{host} = $config->{$_}->{firebird}->{host};
			$self->{$_}->{database} = $config->{$_}->{firebird}->{database};
			$self->{$_}->{database1} = $config->{$_}->{firebird}->{database1};
			$self->{$_}->{dialect} = $config->{$_}->{firebird}->{dialect};
			$self->{$_}->{username} = $config->{$_}->{firebird}->{username};
			$self->{$_}->{password} = $config->{$_}->{firebird}->{password};
		}
	}
  }
  
  sub get_conf {
    my($self, $name) = @_; # ссылка на объект
	my ($mssql, $rm);

	if ($name =~ /mssql/){
		$mssql->{host} = $self->{$name}->{host};
		$mssql->{database} = $self->{$name}->{database};
		#$mssql->{username} = $self->{$name}->{username};
		#$mssql->{password} = $self->{$name}->{password};
		return $mssql;
	}

	if ($name =~ /rm/){
		$rm->{host} = $self->{$name}->{host};
		$rm->{database} = $self->{$name}->{database};
		$rm->{database1} = $self->{$name}->{database1};
		$rm->{dialect} = $self->{$name}->{dialect};
		$rm->{username} = $self->{$name}->{username};
		$rm->{password} = $self->{$name}->{password};
		return $rm;
	}
  } 
}
1;


package firebird;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use DBI;
  use Time::Piece;
  use Data::Dumper;

 sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'error' => 1,
		'log' => LOG->new(),
	};
	
#	$self->{dsn} = "Driver={SQL Server};Server=$self->{host};Database=$self->{database};Trusted_Connection=yes";
  
    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
    return $self;
  }
 
  sub set_con {
    my($self, $host, $database, $dialect, $username, $password) = @_; # ссылка на объект
	$self->{host} = $host;
	$self->{database} = $database;
	$self->{dialect} = $dialect;
	$self->{username} = $username;
	$self->{password} = $password;
	$self->{dsn} = "dbi:Firebird:hostname=$self->{host};db=$self->{database};ib_dialect=$self->{dialect}";
  }

  sub conn {
	my($self) = @_; # ссылка на объект
	eval{ $self->{dbh} = DBI->connect($self->{dsn}, $self->{username}, $self->{password}) || die $self->{log}->save(2, $DBI::errstr); };# обработка ошибки
	if($@) { $self->{error} = 1; } else { $self->{error} = 0; }
  }

  sub get_table {
    my($self, $rolling_mill) = @_; # ссылка на объект
	
	my($sth, $ref, $query, %values, $table, $heat_table);
	
	$query = 'select begindt, NOPLAV as heat, ';
	$query .= 'MARKA as grade, KLASS as standard ';
	$query .= 'FROM melts where state=1';

	eval{ $sth = $self->{dbh}->prepare($query) || die $self->{log}->save(2, "Couldn't execute statement: " . $sth->errstr); };# обработка ошибки

	unless($@) {
		$sth->execute();
		while ($ref = $sth->fetchrow_hashref()) {
			my $timestamp = Time::Piece->strptime($ref->{'BEGINDT'}, "%m/%d/%Y %l:%M:%S %p");
			$heat_table = $ref->{'HEAT'};
			$heat_table =~ s/-/_/g;
#			print(join "\t", 'PARAMS'.$ref->{'HEAT'}, $ref->{'GRADE'}, $ref->{'STANDARD'},
#							 $ref->{'BEGINDT'}, $timestamp->epoch, "\n");

			# rolling mill table format
			# 1 -> PARAMSheat -> PARAMS112345
			# 3 -> PyymmddNheat -> P150231N112345
			if ($rolling_mill =~ /rm1/) {
				$table = "PARAMS". $heat_table;
				$self->{rolling_mill} = $rolling_mill;
			} elsif ($rolling_mill =~ /rm3/) {
				$table = "P". $timestamp->strftime("%y%m%d") ."N$heat_table";
				$self->{rolling_mill} = $rolling_mill;
			}

			%values = ( 'tid' => $timestamp->epoch,
						'timestamp' => $timestamp->epoch,
						'heat' => $ref->{'HEAT'},
						'grade' => $ref->{'GRADE'},
						'standard' => $ref->{'STANDARD'},
						'table' => $table
					);
		}
	} else { $self->{error} = 1; }
	return(%values);
  }

  sub get_values {
    my($self, $table) = @_; # ссылка на объект
	
	my($sth, $ref, $query, %values, $TempLeft, $TempRight,
	   $SectionLeft, $SectionRight, $StrengthClassLeft, $StrengthClassRight);

	$query = "SELECT * FROM $table ";
	$query .= "where recordid=(select max(recordid) FROM $table)";

	eval{ $sth = $self->{dbh}->prepare($query) || die $self->{log}->save(2, "Couldn't execute statement: " . $sth->errstr); };# обработка ошибки

	unless($@) {
		$sth->execute();
		while ($ref = $sth->fetchrow_hashref()) {
			if ($self->{rolling_mill} =~ /rm1/ ) {
			($SectionLeft,  $StrengthClassLeft) = split('_', uc $ref->{'SECTIONL'});
			($SectionRight,  $StrengthClassRight) = split('_', uc $ref->{'SECTIONR'});
			if (250 < $ref->{'TOTPL'}) {
				$TempLeft = $ref->{'TOTPL'};
			} else {
				$TempLeft = 0;
			}
			if (250 < $ref->{'TOTPP'}) {
				$TempRight = $ref->{'TOTPP'};
			} else {
				$TempRight = 0;
			}

			$StrengthClassLeft =~ s/\x0//g; #удаляем NIL символы
			$StrengthClassRight =~ s/\x0//g; #удаляем NIL символы

			# left = 0, right = 1
			%values = ( '0' => {'recordid' => $ref->{'RECORDID'},
								   'section' => $SectionLeft,
								   'strength_class' => $StrengthClassLeft,
								   'temp' => $TempLeft
								},
						'1' => {'recordid' => $ref->{'RECORDID'},
								    'section' => $SectionRight,
								    'strength_class' => $StrengthClassRight,
								    'temp' => $TempRight
								}
					);
			}

			if ($self->{rolling_mill} =~ /rm3/ ) {
				($SectionLeft, $StrengthClassLeft) = split('_', uc $ref->{'SECL'});
				($SectionRight, $StrengthClassRight) = split('_', uc $ref->{'SECR'});
				if (250 < $ref->{'TMOUTL'}) {
					$TempLeft = $ref->{'TMOUTL'};
				} else {
					$TempLeft = 0;
				}
				if (250 < $ref->{'TMOUTR'}) {
					$TempRight = $ref->{'TMOUTR'};
				} else {
					$TempRight = 0;
				}

				$StrengthClassLeft =~ s/\x0//g; #удаляем NIL символы
				$StrengthClassRight =~ s/\x0//g; #удаляем NIL символы

				# left = 0, right = 1
				%values = ( '0' => {'recordid' 		 => $ref->{'RECORDID'},
									'section' 		 => $SectionLeft,
									'strength_class' => $StrengthClassLeft,
									'temp' 			 => $TempLeft,
									},
							'1' => {'recordid' 		 => $ref->{'RECORDID'},
									'section' 		 => $SectionRight,
									'strength_class' => $StrengthClassRight,
									'temp' 			 => $TempRight,
									}
						);
#				print Dumper(\%values);
			}
		}
	} else { $self->{error} = 1; }
	return(%values);
  }

  sub get_host {
    my($self) = @_; # ссылка на объект
	return $self->{host};
  }

  sub get_database {
    my($self) = @_; # ссылка на объект
	return $self->{database};
  }

  sub get_dialect {
    my($self) = @_; # ссылка на объект
	return $self->{dialect};
  }

  sub get_username {
    my($self) = @_; # ссылка на объект
	return $self->{username};
  }

  sub get_password {
    my($self) = @_; # ссылка на объект
	return $self->{password};
  }

  sub get_dsn {
    my($self) = @_; # ссылка на объект
	return $self->{dsn};
  }

  sub get_error {
	my($self) = @_; # ссылка на объект
	return $self->{error};
  }
}
1;

package mssql;{ 
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use DBI;
  use DateTime::Format::Excel;
  use Data::Dumper;  

  sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'error' => 1,
		'log' => LOG->new(),
	};

#	$self->{dsn} = "Driver={SQL Server};Server=$self->{host};Database=$self->{database};Trusted_Connection=yes";

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
    return $self;
  }
 
  sub set_con {
    my($self, $host, $database, $username, $password) = @_; # ссылка на объект
	$self->{host} = $host;
	$self->{database} = $database;
	$self->{username} = $username;
	$self->{password} = $password;
	$self->{dsn} = "Driver={SQL Server};Server=$self->{host};Database=$self->{database};Trusted_Connection=yes";
  }

  sub conn {
	my($self) = @_; # ссылка на объект
	eval{ $self->{dbh} = DBI->connect("dbi:ODBC:$self->{dsn}") || die $self->{log}->save(2, $DBI::errstr); };# обработка ошибки
	if($@) { $self->{error} = 1; } else { $self->{error} = 0; }
  }

  sub get_host {
    my($self) = @_; # ссылка на объект
	return $self->{host};
  }

  sub get_database {
    my($self) = @_; # ссылка на объект
	return $self->{database};
  }

  sub get_username {
    my($self) = @_; # ссылка на объект
	return $self->{username};
  }

  sub get_password {
    my($self) = @_; # ссылка на объект
	return $self->{password};
  }

  sub get_dsn {
    my($self) = @_; # ссылка на объект
	return $self->{dsn};
  }

  sub get_error {
	my($self) = @_; # ссылка на объект
	return $self->{error};
  }

  sub mssql_send {
	my($self, $tid, $heat, $rolling_mill, $grade, $StrengthClass, $section, $standard, $side, $temperature) = @_;
	my($sth, $ref, $query);

	if($self->{error} == 1) {
		$self->conn();
		$self->{log}->save(4, "connected mssql");
	}

#	$self->{log}->save(4, "mssql -> $tid | $heat | $rolling_mill | $grade | $StrengthClass | $section | $standard | $side | $temperature");

	$query = "UPDATE temperature_current SET heat='$heat', ";
	$query .= "grade=N'$grade', strength_class=N'$StrengthClass', ";
	$query .= "section=$section, standard=N'$standard', ";
	$query .= "temperature=$temperature where tid='$tid' ";
	$query .= "and rolling_mill=$rolling_mill and side=$side ";
	$query .= "IF \@\@ROWCOUNT=0 ";
	$query .= "INSERT INTO temperature_current (tid, [timestamp], ";
	$query .= "rolling_mill, heat, grade, strength_class, section, ";
	$query .= "standard, side, temperature) values ( ";
	$query .= "$tid, datediff(ss, '1970/01/01', GETDATE()), ";
	$query .= "$rolling_mill, '$heat', N'$grade', N'$StrengthClass', ";
	$query .= "$section, N'$standard', $side, $temperature )";

	#$self->{log}->save(4, "mssql query -> $query");
	eval{ $sth = $self->{dbh}->prepare($query) || die $self->{log}->save(2, "Couldn't execute statement: " . $DBI::errstr);
		  $sth->execute() || die $self->{log}->save(2, "Couldn't execute statement: " . $DBI::errstr);
		  $sth->finish() || die $self->{log}->save(2, "Couldn't execute statement: " . $DBI::errstr);
	};# обработка ошибки
	if ($@) { $self->{error} = 1; }
}
1;  




package main;
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use threads;
  use DBI;
  use DateTime::Format::Excel;
  use Data::Dumper;
  
  $ENV{'PATH'} = "$ENV{'PATH'};C:\\bin\\QCReadExternalSql\\";

  my $conf = CONF->new();

  # В этом массиве будут храниться ссылки на
  # созданные нити
  my @threads;

  # Создаём 3 нити в режиме по прниципу "создал и забыл", тем
  # самым позволив открыть  параллельно несколько нитей. Объект
  # каждой созданной нити помещается в массив @threads

  my $thread_count = 1;
    push @threads, threads->create(\&execute, 'rm1', $thread_count++);
	push @threads, threads->create(\&execute, 'rm3', $thread_count++);

  # Нити успешно созданы,  ссылки на объекты помещены в массив
  # Теперь мы можем для каждого объекта вызвать метод join(),
  # заставляющий интерпретатор ожидать завершение работы треда.
  foreach my $thread (@threads) {
      # Обратите внимание, что $thread является не объектом, а ссылкой,
      # поэтому управление ему передано не будет.
      $thread->join();
  }

sub execute {
	$0 =~ m/.*[\/\\]/g;
	my ($rolling_mill) = @_;
	
	my $log = LOG->new();
	$log->save(4, "thread -> $rolling_mill");

	# firebird create object
	my $fbsql = firebird->new();
	$fbsql->set_con($conf->get_conf($rolling_mill)->{host}, $conf->get_conf($rolling_mill)->{database},
					$conf->get_conf($rolling_mill)->{dialect}, $conf->get_conf($rolling_mill)->{username},
					$conf->get_conf($rolling_mill)->{password});

	# mssql create object
	my $mssql = mssql->new();
	$mssql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database});

	my $rm = $rolling_mill;
	$rm =~ s/(\D*)//g;

	while (1) {

		if($fbsql->get_error() == 1) {
			$fbsql->conn();
			$log->save(4, "connected fbsql");
		}
		
		my %heat = $fbsql->get_table($rolling_mill);
#		print Dumper(\%heat);
		
		my %values = $fbsql->get_values($heat{'table'});
#		print Dumper(\%values);
		
#		$log->save(4, "left -> $values{'0'}{'recordid'} \t $values{'0'}{'section'} \t $values{'0'}{'strength_class'} \t $values{'0'}{'temp'}");
#		$log->save(4, "right -> $values{'1'}{'recordid'} \t $values{'1'}{'section'} \t $values{'1'}{'strength_class'} \t $values{'1'}{'temp'}");

		for (0..1) {
#			$log->save(4, "start side $_");

			my $side = $_;

			$mssql->mssql_send($heat{'tid'}, $heat{'heat'}, $rm,
							   $heat{'grade'}, $values{$side}{'strength_class'}, $values{$side}{'section'}, $heat{'standard'},
							   $side, $values{$side}{'temp'});

#			$log->save(4, "end side $_");
		}
		
		# clear hash
		delete $heat{$_} for (keys %heat);
		delete $values{$_} for (keys %values);

		sleep(1);
	}
}




}


