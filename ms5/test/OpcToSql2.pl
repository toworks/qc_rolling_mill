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
	  filename => basename($0).".log",
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
	
	#$self->set_log;

    return $self;
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
		$self->{mssql}->{database} = $ref->{'value'} if $ref->{'name'}  =~ /::MsSql::db_name/ ;
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
		}
	} else { exit; }
  }
  
  sub get_conf {
    my($self, $name) = @_; # ссылка на объект
	my ($fbsql, $mssql, $opc);
	
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
  }
}
1;


package OPC;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  use Data::Dumper;

  sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'error' => 0,
		'log' => LOG->new(),
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
	
	$self->create;

    return $self;
  }

  sub create {
	my($self) = @_; # ссылка на объект
    eval{ $self->{opcintf} = Win32::OLE::OPC->new('OPC.Automation',
                                        'Matrikon.OPC.Simulation.1_'); }; 
	unless($@) {
		$self->{opcintf}->MoveToRoot;
		$self->{group} = $self->{opcintf}->OPCGroups->Add('group');
		$self->{items} = $self->{group}->OPCItems;
	} else { $self->{error} = 1; $self->{log}->save(2, "failure to connect to opc"); }
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
	if ($self->{error} == 0) {	
		foreach my $item ($self->{opcintf}->Branches) {
			print $item->{name}, " - \n";
			print(join "\t", $item->{name}, $item->{itemid}, "\n");
		}
		#print Dumper($self->{items}->Item(1));
	#	my $item = $self->{items}->Item(1);
	#	print Dumper($item->Read(2));
	#	print(join "\t", $item->Read(2)->{'TimeStamp'}, $item->Read(2)->{'Value'}, "\n");
		#return $self;
		
		my @tags = @{$self->{tags}};

	  #$self->{opcintf}->Leafs;
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
	}
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
  binmode(STDOUT,':utf8');
  use DBI;
  use Data::Dumper;

 sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
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
	$self->{dbh} = DBI->connect($self->{dsn}, $self->{username}, $self->{password}) || die $self->{log}->save(2, $DBI::errstr);
  }

  sub get_values {
    my($self, $side) = @_; # ссылка на объект
	
	my($sth, $ref, $query, @values);
	
	$query = 'select first 1 ';
	$query .= 'begindt, ';
	$query .= 'NOPLAV as heat, MARKA as grade, KLASS as strength_class, RAZM1 as section, STANDART as standard, SIDE ';
	$query .= 'FROM melts ';
	$query .= "where side = $side ";
	$query .= 'and state = 1 ';
	$query .= 'order by begindt desc';

	$sth = $self->{dbh}->prepare($query);
	eval{ $sth->execute() || die $self->{log}->save(2, "Couldn't execute statement: " . $sth->errstr); };# обработка ошибки
	unless($@) {
		while ($ref = $sth->fetchrow_hashref()) {
#			print(join "\t", $ref->{'HEAT'}, $ref->{'GRADE'}, $ref->{'SECTION'},
#								$ref->{'STANDARD'}, $ref->{'STRENGTH_CLASS'}, "\n");
			push( @values, { 'timestamp' => $ref->{'BEGINDT'}, 'heat' => $ref->{'HEAT'}, 'grade' => $ref->{'GRADE'},
							'section' => $ref->{'SECTION'}, 'standard' => $ref->{'STANDARD'},
							'strength_class' => $ref->{'STRENGTH_CLASS'}, 'side' => $ref->{'SIDE'}, } );
		}
	}
	return(\@values);
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
}
1;
  

package main;
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use threads;
  use DBI;
  use DateTime::Format::Excel;
  use Data::Dumper;
  
  $ENV{'PATH'} = "$ENV{'PATH'};d:\\data\\projects\\perl_qc_rolling_mill.git\\";

  my $conf = CONF->new();
=pod  
  my $opc = OPC->new();
  $opc->set_tags('Random.Int1', 'Random.Real8');

  my @items = $opc->get_values;

  foreach my $item (@items) {
	for (my $i=0; $i <= (keys $item)-1; $i++) {
			#print "$i\n";
			#print $item->[$i]->{'value'}, ;
			print(join "\t", $item->[$i]->{'timestamp'}, $item->[$i]->{'value'}, "\n");	
	}
	print Dumper($item);
  }
=cut

  my $fbsql = firebird->new();
  $fbsql->set_con($conf->get_conf('fbsql')->{host}, $conf->get_conf('fbsql')->{database},
					$conf->get_conf('fbsql')->{dialect}, $conf->get_conf('fbsql')->{username}, $conf->get_conf('fbsql')->{password});
  
  print $conf->get_conf('fbsql')->{username};
  print $fbsql->get_dsn(), "\n";
  print $fbsql->get_username();

  $fbsql->conn();
  my @rows = $fbsql->get_values(0);

  my %heat_left = get_current_heat(@rows);
  
   for my $key ( keys %heat_left ) {
        my $value = $heat_left{$key};
        print "$key => $value\n";
   }
=k

    try
       SQuery.Close;
       SQuery.SQL.Clear;
       SQuery.SQL.Add('SELECT * FROM settings');
       SQuery.Open;
   except
     on E: Exception do
       SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
   end;

   while not SQuery.Eof do
   begin
     if SQuery.FieldByName('name').AsString = '::heat::side'+inttostr(InSide) then
       heat := SQuery.FieldByName('value').AsString;
     if SQuery.FieldByName('name').AsString = '::tid::side'+inttostr(InSide) then
       tid := SQuery.FieldByName('value').AsString;
     SQuery.Next;
   end;

   if heat <> main.Heat then
   begin
       tid := inttostr(DateTimeToUnix(NOW));
       try
           SQuery.Close;
           SQuery.SQL.Clear;
           SQuery.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
           SQuery.SQL.Add('VALUES (''::heat::side'+inttostr(InSide)+''',');
           SQuery.SQL.Add(''''+main.Heat+''')');
           SQuery.ExecSQL;
       except
         on E: Exception do
           SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
       end;
       try
           SQuery.Close;
           SQuery.SQL.Clear;
           SQuery.SQL.Add('INSERT OR REPLACE INTO settings (name, value)');
           SQuery.SQL.Add('VALUES (''::tid::side'+inttostr(InSide)+''',');
           SQuery.SQL.Add(''''+tid+''')');
           SQuery.ExecSQL;
       except
         on E: Exception do
           SaveLog('error' + #9#9 + E.ClassName + ', с сообщением: ' + E.Message);
       end;
   end;
=cut 
  
 
  my $log = LOG->new();
  $log->save(0, "dsdsdas");
exit;



sub get_current_heat {
  my (@rows) = @_;
  
  my %values;
  foreach my $row (@rows) {
	for (my $i=0; $i <= (keys $row)-1; $i++) {
		print(join "\t", $row->[$i]->{'side'}, $row->[$i]->{'heat'}, $row->[$i]->{'grade'}, $row->[$i]->{'timestamp'}, fb_str2timestamp($row->[$i]->{'timestamp'}), "\n");
		 %values = (
					'side' => $row->[$i]->{'side'},
					'heat' => $row->[$i]->{'heat'},
					'grade' => $row->[$i]->{'grade'},
					'dt' => $row->[$i]->{'timestamp'},
					'timestamp' => fb_str2timestamp($row->[$i]->{'timestamp'})
				);
	}
  }
  #print Dumper(%values);
  return(%values);
}

sub fb_str2timestamp {
	#my ($year, $month, $day, $hour, $min, $sec, $nsec) = shift =~ /^(\d+)\/(\d+)\/(\d+)\s(\d+)\:(\d+)\:(\d+)\.(\d+)$/ or die;
	#my ($year, $month, $day, $hour, $min, $sec) = shift =~ m!(\d{4})/(\d{2})/(\d{2})\s(\d{2}):(\d{2}):(\d{2})!;
	my ($day, $month, $year, $hour, $min, $sec) = shift =~ m!(\d{2}).(\d{2}).(\d{4})\s(\d{2}):(\d{2}):(\d{2})!;
	#print(join "\t", $year, $month, $day, $hour, $min, $sec, "\n");

	my $datetime = DateTime->new( year       => $year,
								  month      => $month,
								  day        => $day,
								  hour       => $hour,
								  minute     => $min,
								  second     => $sec,
								  nanosecond => 000000000
								);
	return $datetime->epoch;
}

=comment
  # В этом массиве будут храниться ссылки на
  # созданные нити
  my @threads;

  # Создаём 3 нити в режиме по прниципу "создал и забыл", тем
  # самым позволив открыть  параллельно несколько нитей. Объект
  # каждой созданной нити помещается в массив @threads

  $ENV{'PATH'} = "$ENV{'PATH'};d:\\data\\projects\\perl_qc_rolling_mill.git\\";

  my $ms_sql = mssql->new();
  $ms_sql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database}, '', '');
  my $values = $ms_sql->get_values;

  my $thread_count = 1;
  my @table_prefix = get_tables($values, "АЦ3");
  for my $tp (@table_prefix){
	push @threads, threads->create(\&execute_ac3, $tp, "АЦ3", $values, $thread_count);
	$thread_count++;
  }

  @table_prefix = get_tables($values, "АЦ1");
  for my $tp (@table_prefix){
	push @threads, threads->create(\&execute_ac1, $tp, "АЦ1", $values, $thread_count);
	$thread_count++;
  }

  push @threads, threads->create(\&execute_weight, "weight", $thread_count++);

#  for my $i (1..4) {
#    if ($i == 1) {
#	  push @threads, threads->create(\&execute_ac1, $i);
#   }
#    if ($i == 3) {
#	  push @threads, threads->create(\&execute_ac3, $i);
#    }
#    if ($i == 4) {
#	  push @threads, threads->create(\&execute_weight, $i);
#   }
#  }

  # Нити успешно созданы,  ссылки на объекты помещены в массив
  # Теперь мы можем для каждого объекта вызвать метод join(),
  # заставляющий интерпретатор ожидать завершение работы треда.
  foreach my $thread (@threads) {
      # Обратите внимание, что $thread является не объектом, а ссылкой,
      # поэтому управление ему передано не будет.
      $thread->join();
  }
  
sub dec2bin {
    my ($str) = unpack("B32", pack("N", shift));
	return substr($str, -16);
}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub str2exel_date {
	my ($year, $month, $day, $hour, $min, $sec, $nsec) = shift =~ /^(\d+)\-(\d+)\-(\d+)\s(\d+)\:(\d+)\:(\d+)\.(\d+)$/ or die;
#	print(join "\t", $year, $month, $day, $hour, $min, $sec, $nsec, "\n");

	my $datetime = DateTime->new( year       => $year,
								  month      => $month,
								  day        => $day,
								  hour       => $hour,
								  minute     => $min,
								  second     => $sec,
								  nanosecond => $nsec
								);
	my $excel_date = DateTime::Format::Excel->format_datetime( $datetime );
	return $excel_date;
}

sub get_tables {
	my($values, $ap) = @_;
	my %unique = ();
	for my $c ( sort keys %$values ) {
		if ( $values->{$c}->{ac} =~ /$ap/ ) {
			$unique{$values->{$c}->{table}}++;
		}
	}
	my @tables = sort keys %unique;
	return @tables;
}

sub timestamp2datetime {
	my($timestamp) = @_;
	my($sec, $min, $hour, $day, $mon, $year, undef, undef, undef) = localtime($timestamp);
	my $datetime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
	return $datetime;
}

sub execute_ac1 {
	$0 =~ m/.*[\/\\]/g;
	my ($tp, $type, $values) = @_;
	my($table, $dsn, $dbh, $query, $sth, $ref, $ms_sql, $max_timestamp, $datetime, @array_values);
	print "thread -> ", $type, "\ttable prefix -> ", $tp, "\n";
	
	$dsn = "dbi:Firebird:hostname=".$conf->get_conf('ac1')->{host}.";db=".$conf->get_conf('ac1')->{database}.";ib_dialect=".$conf->get_conf('ac1')->{dialect};

	while (1) {
		$dbh = DBI->connect($dsn, $conf->get_conf('ac1')->{username}, $conf->get_conf('ac1')->{password}) || die "Error: $DBI::errstr"; 
		$query = "select INDEXCURTABLE from ARCGRINF where CODEARCGR=0";
		$sth = $dbh->prepare($query);
		eval{ $sth->execute() or die "Couldn't execute statement: " . $sth->errstr; };# обработка ошибки
		unless($@) {
			while ($ref = $sth->fetchrow_hashref()) {
				#print(join "\t", ($ref->{'HEAT'}, $ref->{'BEGINDT'}, 'PARAMS'.$ref->{'HEAT'}))."\n\n";
				$table = $ref->{'INDEXCURTABLE'};
			}
		}

		$ms_sql = mssql->new();
		$ms_sql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database}, '', '');
#		$values = $ms_sql->get_values;
		$max_timestamp = $ms_sql->get_max_timestamp($type, lc($tp));

		$query = "SELECT * FROM $tp\_$table where dtpoint > $max_timestamp";

		$sth = $dbh->prepare($query);
		eval{ $sth->execute() or die "Couldn't execute statement: " . $sth->errstr; };# обработка ошибки
			
		unless($@) {# обработка ошибки
			while ($ref = $sth->fetchrow_hashref()) {
				#print ("\n", join "\t", ("table -> $tp\_$table", $type, $ref->{DTPOINT}, "\n"));
				for my $c ( sort keys %$values ) {
					if ($values->{$c}->{ac} =~ /АЦ1/) {
						if ($values->{$c}->{table} =~ /$tp/) {
							#print $values->{$c}->{ac}, "\t", $values->{$c}->{unit}, "\t", $values->{$c}->{table}, "\t", $values->{$c}->{value}, "\t", $values->{$c}->{bit}, "\n";
							#print $ref->{$values->{$c}->{value}}, "\n";
							if ($values->{$c}->{bit} ne -1 ){
								my $datetime = DateTime::Format::Excel->parse_datetime( $ref->{'DTPOINT'} );							
								push @array_values, { '1' => $ref->{'DTPOINT'}, '2' => $datetime->strftime('%F %T.%3N'), '3' => $values->{$c}->{unit}, '4' => $ref->{$values->{$c}->{value}},
								'5' => &dec2bin($ref->{$values->{$c}->{value}}), '6' => substr(&dec2bin($ref->{$values->{$c}->{value}}), -$values->{$c}->{bit}-1, 1) };								
							}else{
								my $datetime = DateTime::Format::Excel->parse_datetime( $ref->{'DTPOINT'} );
								push @array_values, { '1' => $ref->{'DTPOINT'}, '2' => $datetime->strftime('%F %T.%3N'), '3' => $values->{$c}->{unit}, '4' => $ref->{$values->{$c}->{value}}, '5' => undef, '6' => undef };
							}
						}
					}
				}
			}
		}
		eval{ $sth->finish(); };# обработка ошибки
		$dbh->disconnect;

		print (join "\t", ("table -> $tp\_$table", $type, "\n"));

		$ms_sql->mssql_send(@array_values);
		@array_values = undef; #clear values
		sleep(60);
	}
}


sub execute_ac3 {
	$0 =~ m/.*[\/\\]/g;
	my ($tp, $type, $values) = @_;
	my($table, $dsn_set, $dsn_arc, $dbh, $query, $sth, $ref, $ms_sql, $max_timestamp, $datetime, @array_values);
	print "thread -> ", $type, "\ttable prefix -> ", $tp, "\n";
	
	$dsn_set = "dbi:Firebird:hostname=".$conf->get_conf('ac3')->{host}.";db=".$conf->get_conf('ac3')->{database}.";ib_dialect=".$conf->get_conf('ac3')->{dialect};
	$dsn_arc = "dbi:Firebird:hostname=".$conf->get_conf('ac3')->{host}.";db=".$conf->get_conf('ac3')->{database1}.";ib_dialect=".$conf->get_conf('ac3')->{dialect};	

	while (1) {
		$dbh = DBI->connect($dsn_set, $conf->get_conf('ac3')->{username}, $conf->get_conf('ac3')->{password}) || die "Error: $DBI::errstr"; 	
		$query = "select indexcurarctable from setarcgr where code=0";
		$sth = $dbh->prepare($query);
		eval{ $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;	};# обработка ошибки
		unless($@) {
			while ($ref = $sth->fetchrow_hashref()) {
				#print(join "\t", ($ref->{'HEAT'}, $ref->{'BEGINDT'}, 'PARAMS'.$ref->{'HEAT'}, "\n"));
				$table = $ref->{'INDEXCURARCTABLE'};
			}
			$sth->finish();
		}
		$dbh->disconnect;

		$ms_sql = mssql->new();
		$ms_sql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database}, '', '');
#		$values = $ms_sql->get_values;
		$max_timestamp = $ms_sql->get_max_timestamp($type, lc($tp));

		$dbh = DBI->connect($dsn_arc, $conf->get_conf('ac3')->{username}, $conf->get_conf('ac3')->{password}) || die "Error: $DBI::errstr"; 	

		$query = "SELECT * FROM $tp\_$table where dtpoint > $max_timestamp";
		$sth = $dbh->prepare($query);
		eval{ $sth->execute() or die "Couldn't execute statement: " . $sth->errstr; };# обработка ошибки

		unless($@) {# обработка ошибки
			while ($ref = $sth->fetchrow_hashref()) {
#				print "\n";
#				print (join "\t", "table -> $tp\_$table", $type, $ref->{DTPOINT}, "\n");
				# type material
				my ($type);
				if ( ($ref->{VALUEAPAR424}||0) + ($ref->{VALUEAPAR425}||0) > 0) {
					$type = 1;
					#print "value -> $ref->{VALUEAPAR424}+$ref->{VALUEAPAR425} \t type -> $type \n"; #Use of uninitialized value in addition (+) example: my $d = ($a||0)+$b; # no warning
				} elsif ( ($ref->{VALUEAPAR426}||0) + ($ref->{VALUEAPAR427}||0) > 0) {
					$type = 2;
					#print "value -> $ref->{VALUEAPAR426}+$ref->{VALUEAPAR427} \t type -> $type \n";
				} elsif ( ($ref->{VALUEAPAR428}||0) + ($ref->{VALUEAPAR429}||0) > 0) {
					$type = 3;
					#print "value -> $ref->{VALUEAPAR428}+$ref->{VALUEAPAR429} \t type -> $type \n";
				}
				for my $c ( sort keys %$values ) {
					if ($values->{$c}->{ac} =~ /АЦ3/) {
						if ($values->{$c}->{table} =~ /$tp/) {
							#print $values->{$c}->{ac}, "\t", $values->{$c}->{unit}, "\t", $values->{$c}->{table}, "\t", $values->{$c}->{value}, "\t", $values->{$c}->{bit}, "\n";
							#print $ref->{$values->{$c}->{value}}, "\n";
							if ($values->{$c}->{bit} ne -1 ){
								my $datetime = DateTime::Format::Excel->parse_datetime( $ref->{'DTPOINT'} );
								push @array_values, { '1' => $ref->{'DTPOINT'}, '2' => $datetime->strftime('%F %T.%3N'), '3' => $values->{$c}->{unit}, '4' => $ref->{$values->{$c}->{value}},
								'5' => &dec2bin($ref->{$values->{$c}->{value}}), '6' => substr(&dec2bin($ref->{$values->{$c}->{value}}), -$values->{$c}->{bit}-1, 1) };
							}else{
								my $datetime = DateTime::Format::Excel->parse_datetime( $ref->{'DTPOINT'} );
								push @array_values, { '1' => $ref->{'DTPOINT'}, '2' => $datetime->strftime('%F %T.%3N'), '3' => $values->{$c}->{unit}, '4' => $ref->{$values->{$c}->{value}}, '5' => undef, '6' => $type || undef };
							}
						}
					}
				}
			}
		}
		eval{ $sth->finish(); };# обработка ошибки
		$dbh->disconnect;

		print (join "\t", ("table -> $tp\_$table", $type, "\n"));

		$ms_sql->mssql_send(@array_values);
		@array_values = undef; #clear values
		sleep(30);
	}
}


sub execute_weight {
	$0 =~ m/.*[\/\\]/g;
	my($type) = shift;
	my($dsn, $dbh, $query, $sth, $ref, $ms_sql, $ms_sql_weitht, $max_timestamp, @array_values);
	print "thread -> ", $type, "\n";
		
	$ms_sql_weitht = mssql->new();
	$ms_sql_weitht->set_con($conf->get_conf('weight')->{host}, $conf->get_conf('weight')->{database}, $conf->get_conf('weight')->{username}, $conf->get_conf('weight')->{password});

	$dsn = "Driver={SQL Server};Server=".$conf->get_conf('weight')->{host}.";Database=".$conf->get_conf('weight')->{database}.";UID=".$conf->get_conf('weight')->{username}.";PWD=".$conf->get_conf('weight')->{password};

	while (1) {
		$ms_sql = mssql->new();
		$ms_sql->set_con($conf->get_conf('mssql')->{host}, $conf->get_conf('mssql')->{database}, '', '');
		$max_timestamp = $ms_sql->get_max_timestamp($type, uc('VALUE_DATA'));

		if ($max_timestamp == 0) { $max_timestamp = timestamp2datetime(time); }else{ $max_timestamp = timestamp2datetime($max_timestamp) }

		$dbh = DBI->connect("dbi:ODBC:$dsn") || die "Error: $DBI::errstr"; 
		$query = "SELECT dt, id_measuring as agreg, value as flags FROM VALUE_DATA where dt > ?";
		$sth = $dbh->prepare($query);
		eval{ $sth->execute( $max_timestamp ) or die "Couldn't execute statement: " . $sth->errstr; };# обработка ошибки

		unless($@) {
			while ($ref = $sth->fetchrow_hashref()) {
				print(join "\t", ($ref->{'dt'}, $ref->{'agreg'}, $ref->{'flags'}, "\n"));
#				eval { $ms_sql->mssql_send(str2exel_date($ref->{'dt'}), $ref->{'agreg'}, $ref->{'flags'}, '5' => undef, '6' => undef);	};
				push @array_values, { '1' => str2exel_date($ref->{'dt'}), '2' => $ref->{'dt'}, '3' => $ref->{'agreg'}, '4' => $ref->{'flags'}, '5' => undef, '6' => undef };
			}
			$sth->finish();
		}
		$dbh->disconnect;
		
		print (join "\t", ($type, "\n"));
		
		$ms_sql->mssql_send(@array_values);
		@array_values = undef; #clear values
		sleep(10);
	}
}
=cut

