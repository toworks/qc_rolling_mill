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
  use DBI;
  use Data::Dumper;

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

	my ($dbh, $sth, $query);
	$dbh = DBI->connect("dbi:SQLite:dbname=data.sdb","","") || die $self->{log}->save(2, $DBI::errstr);

	$query = "select * from settings order by name asc";
		
	eval{ $sth = $dbh->prepare($query) || die $self->{log}->save(2, $DBI::errstr); };
	unless($@) {
		$sth->execute();

		while (my $ref = $sth->fetchrow_hashref()) {
			# firebird
			$self->{firebird}->{host} = $ref->{'value'} if $ref->{'name'}  =~ /::FbSql::ip/ ;
			$self->{firebird}->{database} = $ref->{'value'} if $ref->{'name'}  =~ /::FbSql::db_name/ ;
			$self->{firebird}->{dialect} = $ref->{'value'} if $ref->{'name'}  =~ /::FbSql::dialect/ ;
			$self->{firebird}->{username} = $ref->{'value'} if $ref->{'name'}  =~ /::FbSql::user/ ;
			$self->{firebird}->{password} = $ref->{'value'} if $ref->{'name'}  =~ /::FbSql::password/ ;

			# mssql
			$self->{mssql}->{host} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::ip/ ;
			$self->{mssql}->{database} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::database/ ;
			$self->{mssql}->{username} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::user/ ;
			$self->{mssql}->{password} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::password/ ;
			$self->{mssql}->{port} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::port/ ;

			# opc
			$self->{opc}->{server_name} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::server_name/ ;
			$self->{opc}->{tag_aural_alert} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_aural_alert/ ;
			$self->{opc}->{tag_cogging_left} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_cogging_left/ ;
			$self->{opc}->{tag_cogging_right} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_cogging_right/ ;
			$self->{opc}->{tag_light_alert_left} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_light_alert_left/ ;
			$self->{opc}->{tag_light_alert_right} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_light_alert_right/ ;
			$self->{opc}->{tag_temp_left} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_temp_left/ ;
			$self->{opc}->{tag_temp_right} = $ref->{'value'} if $ref->{'name'}  =~ /::OPC::tag_temp_right/ ;
			
			# rolling_mill
			$self->{rolling_mill} = $ref->{'value'} if $ref->{'name'}  =~ /::RollingMill::number/ ;
		}
	} else { exit; }
  }
  
  sub get_conf {
    my($self, $name) = @_; # ссылка на объект
	my ($fbsql, $mssql, $opc, $rolling_mill);
	
	if ($name =~ /fbsql/){
		# firebird
		$fbsql->{host} = $self->{firebird}->{host};
		$fbsql->{database} = $self->{firebird}->{database};
		$fbsql->{dialect} = $self->{firebird}->{dialect};
		$fbsql->{username} = $self->{firebird}->{username};
		$fbsql->{password} = $self->{firebird}->{password};
		return $fbsql;
	}
	
	if ($name =~ /mssql/){
		$mssql->{host} = $self->{mssql}->{host};
		$mssql->{database} = $self->{mssql}->{database};
		$mssql->{username} = $self->{mssql}->{username};
		$mssql->{password} = $self->{mssql}->{password};
		$mssql->{port} = $self->{mssql}->{port};
		return $mssql;
	}

	if ($name =~ /opc/){
		$opc->{server_name} = $self->{opc}->{server_name};
		$opc->{tag_aural_alert} = $self->{opc}->{tag_aural_alert};
		$opc->{tag_cogging_left} = $self->{opc}->{tag_cogging_left};
		$opc->{tag_cogging_right} = $self->{opc}->{tag_cogging_right};
		$opc->{tag_light_alert_left} = $self->{opc}->{tag_light_alert_left};
		$opc->{tag_light_alert_right} = $self->{opc}->{tag_light_alert_right};
		$opc->{tag_temp_left} = $self->{opc}->{tag_temp_left};
		$opc->{tag_temp_right} = $self->{opc}->{tag_temp_right};
		return $opc;
	}

	if ($name =~ /rolling_mill/){
		$rolling_mill->{rolling_mill} = $self->{rolling_mill};
		return $rolling_mill;
	}
  }
}
1;


package OPC;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  use Data::Dumper;

  sub new {
    # получаем имя класса
    my($class, $opc_name, $opc_ip) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'opc_name' => $opc_name,
		'opc_ip' => $opc_ip,
		'error' => 1,
		'log' => LOG->new(),
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент

    return $self;
  }

  sub connect {
	my($self) = @_; # ссылка на объект
    eval{ $self->{opcintf} = Win32::OLE::OPC->new('OPC.Automation',
												  $self->{opc_name},
												  $self->{opc_ip}) or die $self->{log}->save(2, "failure to connect to opc"); };
#												  $self->{opc_ip})};
	unless($@) {
		$self->{opcintf}->MoveToRoot;
		$self->{group} = $self->{opcintf}->OPCGroups->Add('_group_');
		$self->{items} = $self->{group}->OPCItems;
		$self->{error} = 0;
	} else { $self->{error} = 1; }
  }

  sub set_tags {
	my($self, @tags) = @_; # ссылка на объект
	if ($self->{error} == 0) {
		foreach my $tag (@tags) {
			$self->{items}->AddItem($tag, $self->{opcintf});
			push( @{$self->{tags}}, $tag );
			#print $tag."\n";
		}
	}
  }

  sub get_values {
	my($self) = @_; # ссылка на объект
	my %item_handles;
#		foreach my $item ($self->{opcintf}->Branches) {
#			print $item->{name}, " - \n";
#			print(join "\t", $item->{name}, $item->{itemid}, "\n");
#		}
		#print Dumper($self->{items}->Item(1));
	#	my $item = $self->{items}->Item(1);
	#	print Dumper($item->Read(2));
	#	print(join "\t", $item->Read(2)->{'TimeStamp'}, $item->Read(2)->{'Value'}, "\n");
		#return $self;
		
		my @tags = @{$self->{tags}};
		eval{ $self->{opcintf}->Leafs; };
=c
		my @item_handles;
		for (my $i = 1; $i < $self->{opcintf}->{count}+1; $i++) {
			my $item = $self->{items}->Item($i);
			my $timestamp = $item->Read($OPCCache)->{'TimeStamp'};
			my $datetime = $timestamp->Date("yyyy-MM-dd"). " " .$timestamp->Time("HH:mm:ss");
			my $value = $item->Read($OPCCache)->{'Value'};
			#print(join "\t", $item->Read($OPCCache)->{'TimeStamp'}, $item->Read($OPCCache)->{'Value'}, "\n");
			push( @item_handles, {tag =>  $tags[$i-1], 'timestamp' => $datetime, 'value' => $value} );
		}
		
			foreach my $item ($self->{opcintf}->Branches) {
			  print $item->{itemid}, "\n";
			}
		return(\@item_handles);
=cut
		eval{
		#		for (my $i = 1; $i < $self->{opcintf}->{count}+1; $i++) {
				for (my $i = 1; $i < $#tags+2; $i++) {
					my $item = $self->{items}->Item($i);
					my $timestamp = $item->Read($OPCCache)->{'TimeStamp'};
					my $datetime = $timestamp->Date("yyyy-MM-dd"). " " .$timestamp->Time("HH:mm:ss");
					my $value = $item->Read($OPCCache)->{'Value'};
					#print(join "\t", $item->Read($OPCCache)->{'TimeStamp'}, $item->Read($OPCCache)->{'Value'}, "\n");
					#%item_handles = ( $tags[$i-1] => { 'timestamp' => $datetime, 'value' => $value } );
					$item_handles{ $tags[$i-1] } = {
													'timestamp' => $datetime,
													'value' => $value,
												};
				}
		};
		if ($@) {
			$self->{error} = 1;
			$self->{log}->save(2, "failure to get values to opc");
		}
	return(%item_handles);
  }
  
   sub get_error {
		my($self) = @_; # ссылка на объект
		return $self->{error};
   }
=comm  
  for (my $i = 1; $i < $self->{opcintf}->{count}+1; $i++) {
    #my $item = $self->{opcintf}->Item($i);
	my $item = $self->{items}->Item($i);
    #print $item->{name}, " ", $item->{itemid}, "\n";
	print Dumper($item->Read(2));
	print $i, "\n";
	print(join "\t", $item->Read(2)->{'TimeStamp'}, $item->Read(2)->{'Value'}, "\n");
  }	
=comm	
	    foreach $item ($self->{opcintf}->Leafs) {
          print $item->{name}, "\n";
          my %result = $self->{opcintf}->ItemData($item->{itemid});
          for my $attrib (keys %result) {
            print "        [", $attrib, " = '", $result{$attrib}, "']", "\n";
          }
          print "\n";
        }
        foreach $item ($self->{opcintf}->Branches) {
          print $item->{name}, "\n";
        }
=cut
=comm
        foreach $item ($opcintf->Leafs) {
          print $item->{name}, "\n";
          my %result = $opcintf->ItemData($item->{itemid});
          for $attrib (keys %result) {
            print "        [", $attrib, " = '", $result{$attrib}, "']", "\n";
          }
          print "\n";
        }
        foreach $item ($opcintf->Branches) {
          print $item->{name}, "\n";
        }
=cut
=comm
		my $group = $opcintf->OPCGroups->Add('grp');
		my $items = $group->OPCItems;
		$items->AddItem("Random.Real8", $opcintf);
		while (1) {		

		my $item = $items->Item(1);
		#print Dumper($item->Read(2));
		print(join "\t", $item->Read(2)->{'TimeStamp'}, $item->Read(2)->{'Value'}, "\n");
		}
=cut
}
1;


package firebird;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use DBI;
  use Date::Parse;
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

  sub get_values {
    my($self, $side) = @_; # ссылка на объект
	
	my($sth, $ref, $query, %values, $timestamp);
	
	$query = 'select first 1 ';
	$query .= 'begindt, ';
	$query .= 'NOPLAV as heat, MARKA as grade, KLASS as strength_class, RAZM1 as section, STANDART as standard, SIDE ';
	$query .= 'FROM melts ';
	$query .= "where side = $side ";
	$query .= 'and state = 1 ';
	$query .= 'order by begindt desc';

	eval{ $sth = $self->{dbh}->prepare($query) || die $self->{log}->save(2, "Couldn't execute statement: " . $sth->errstr); };# обработка ошибки

	unless($@) {
		$sth->execute();
		while ($ref = $sth->fetchrow_hashref()) {
			$timestamp = str2time($ref->{'BEGINDT'});
#			print(join "\t", $ref->{'HEAT'}, $ref->{'GRADE'}, $ref->{'STANDARD'},
#							 $ref->{'BEGINDT'}, $timestamp, "\n");

			%values = ( 'tid' => $timestamp,
						'timestamp' => $timestamp,
						'heat' => $ref->{'HEAT'},
						'grade' => $ref->{'GRADE'},
						'section' => $ref->{'SECTION'},
						'standard' => $ref->{'STANDARD'},
						'strength_class' => $ref->{'STRENGTH_CLASS'},
						'side' => $ref->{'SIDE'}
					);
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
  use DBI;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
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
	$self->{dsn} = "Driver={SQL Server};Server=$self->{host};Database=$self->{database};Trusted_Connection=NO";
  }

  sub conn {
	my($self) = @_; # ссылка на объект
	eval{ $self->{dbh} = DBI->connect("dbi:ODBC:$self->{dsn};UID=$self->{username};PWD=$self->{password}") || die $self->{log}->save(2, $DBI::errstr); };# обработка ошибки
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

	#$self->{log}->save(4, "mssql -> $tid | $heat | $rolling_mill | $grade | $StrengthClass | $section | $standard | $side | $temperature");

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
  use Data::Dumper;
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  
  $ENV{'PATH'} = "$ENV{'PATH'};D:\\Program\\QCOpcToSql\\";

  my $conf = CONF->new();

  # В этом массиве будут храниться ссылки на
  # созданные нити
  my @threads;

  # Создаём 3 нити в режиме по прниципу "создал и забыл", тем
  # самым позволив открыть  параллельно несколько нитей. Объект
  # каждой созданной нити помещается в массив @threads
=comments
  my $ms_sql = mssql->new();
  $ms_sql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database}, '', '');
  my $values = $ms_sql->get_values;
=cut
  my $thread_count = 1;
  push @threads, threads->create(\&execute, 'mc5', $thread_count++);
=comments
  @table_prefix = get_tables($values, "АЦ1");
  for my $tp (@table_prefix){
	push @threads, threads->create(\&execute_ac1, $tp, "АЦ1", $values, $thread_count);
	$thread_count++;
  }


  push @threads, threads->create(\&execute_weight, "weight", $thread_count++);
=cut

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
	my ($thread) = @_;
	
	my (%heat, %items);
	
	my $log = LOG->new();
	$log->save(4, "thread -> $thread");

	# firebird create object
	my $fbsql = firebird->new();
	$fbsql->set_con($conf->get_conf('fbsql')->{host}, $conf->get_conf('fbsql')->{database},
					$conf->get_conf('fbsql')->{dialect}, $conf->get_conf('fbsql')->{username}, $conf->get_conf('fbsql')->{password});

	# opc create object
	my $opc = OPC->new($conf->get_conf('opc')->{server_name}, $conf->get_conf('fbsql')->{host});

	# mssql create object
	my $mssql = mssql->new();
	$mssql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database},
					$conf->get_conf('mssql')->{username}, $conf->get_conf('mssql')->{password});

	while (1) {
		if($opc->get_error() == 1) {
			$log->save(4, "connected opc");
			$opc = undef;
			$opc = OPC->new($conf->get_conf('opc')->{server_name}, $conf->get_conf('fbsql')->{host});
			$opc->connect();
			$opc->set_tags( $conf->get_conf('opc')->{tag_cogging_right},
						  $conf->get_conf('opc')->{tag_aural_alert},
						  $conf->get_conf('opc')->{tag_temp_left},
						  $conf->get_conf('opc')->{tag_light_alert_right},
						  $conf->get_conf('opc')->{tag_cogging_left},
						  $conf->get_conf('opc')->{tag_light_alert_left},
						  $conf->get_conf('opc')->{tag_temp_right}
		  );
		}
		
		%items = $opc->get_values;
#		for my $key ( keys %items ) {
#			print "$key => $items{$key}->{timestamp}\n";
#			print "$key => $items{$key}->{value}\n";
#		}

		if($fbsql->get_error() == 1) {
			$log->save(4, "connected firebird");
			$fbsql->conn();
		}
		
		for (0..1) {

			%heat = $fbsql->get_values($_);

#			for my $key ( keys %heat ) {
#				my $value = $heat{$key};
#				$log->save(4, "$key => $value");
#			}

			my $tag;

			if ($_ == 0) {
				$tag = $conf->get_conf('opc')->{tag_temp_left};
			} elsif ($_ == 1) {
				$tag = $conf->get_conf('opc')->{tag_temp_right};
			}

			my $temperature = $items{$tag}->{value};
			$temperature = 0 if $temperature <= 250; # limits 250 = 0

			$mssql->mssql_send($heat{'tid'}, $heat{'heat'}, $conf->get_conf('rolling_mill')->{rolling_mill},
							   $heat{'grade'}, $heat{'strength_class'}, $heat{'section'}, $heat{'standard'},
							   $heat{'side'}, $temperature);
		}

		sleep(1);
	}
}




}


