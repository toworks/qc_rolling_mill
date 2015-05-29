#!c:\bin\perl\perl\bin\perl.exe
#use strict;
#use warnings;


use threads;
use DBI;
use Time::Piece;


#my $t = Time::Piece->strptime('06.10.2012 21:02:00',"%d.%m.%Y %H:%M:%S");
#my $t = Time::Piece->strptime('1/22/2015 9:40:57 AM',"%e/%d/%Y %l:%M:%S %p");
#print $t->epoch, "\n";
#exit;

# В этом массиве будут храниться ссылки на
# созданные нити
my @threads;

# Создаём 3 нити в режиме по прниципу "создал и забыл", тем
# самым позволив открыть  параллельно несколько нитей. Объект
# каждой созданной нити помещается в массив @threads
for my $i (1..4) {
  if  ($i <= 3) {
	push @threads, threads->create(\&get_now, $i);
  }
  if ($i == 4) {
	push @threads, threads->create(\&execute, $i);
  }
}

# Нити успешно созданы,  ссылки на объекты помещены в массив
# Теперь мы можем для каждого объекта вызвать метод join(),
# заставляющий интерпретатор ожидать завершение работы треда.

foreach my $thread (@threads) {
    # Обратите внимание, что $thread является не объектом, а ссылкой,
    # поэтому управление ему передано не будет.
    $thread->join();
}

sub get_now
{
    my $num = shift;
    print "thread ", $num, " => ", time(), "\n";
    sleep 1;
}

sub execute {
#	system('set PATH=%PATH%;D:\\data\\projects\\dll\\');
	system('set PATH=%PATH%;c:\\bin\\QCReadExternalSql\\');

	$dsn = 'dbi:Firebird:hostname=10.21.120.114;db=D:\db_New\Termo.gdb;ib_dialect=1';
	$dbh =  DBI->connect($dsn, "sysdba", "masterkey") or die "Can't connect to $data_source: $DBI::errstr";

	while (true) {
		my $query = "select begindt, NOPLAV as heat, ".
					"MARKA as grade, KLASS as standard ".
					"FROM melts where state=1";
		my $sth  = $dbh->prepare($query);
		$sth ->execute();
		while (my $ref = $sth->fetchrow_hashref()) {
			#print(join "\t", ($ref->{'HEAT'}, $ref->{'BEGINDT'}, 'PARAMS'.$ref->{'HEAT'}))."\n\n";
#			$timestamp = $ref->{'BEGINDT'};
#			$timestamp = Time::Piece->strptime($ref->{'BEGINDT'}, "%d.%m.%Y %H:%M:%S");
			$timestamp = Time::Piece->strptime($ref->{'BEGINDT'}, "%e/%d/%Y %l:%M:%S %p");
			$heat = $ref->{'HEAT'};
			$heat =~ s/-/_/g;
			$grade = $ref->{'GRADE'};
			$standard = $ref->{'STANDARD'};
		}
		$sth->finish();
#print $heat. $heat. $grade.$standard. 'PARAMS'.$heat;
#		print (join "\t", ($heat, $heat, $grade, $standard, 'PARAMS'.$heat))."\n\n";
#		print "\t".time()."\n";


		my $sth = $dbh->prepare("SELECT * FROM PARAMS".$heat." where recordid=(select max(recordid) FROM PARAMS".$heat.")");
			$sth ->execute();
			while (my $ref = $sth->fetchrow_hashref()) {
			#print(join "\t", ($ref->{'RECORDID'}, $ref->{'SECTIONL'}, $ref->{'SECTIONR'}, $ref->{'TOTPL'}, $ref->{'TOTPP'}))."\n\n";
			$recordid = $ref->{'RECORDID'};
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
		}
		$sth->finish();

		$StrengthClassLeft =~ s/\x0+$//g; #удаляем NIL символы
		$StrengthClassRight =~ s/\x0+$//g; #удаляем NIL символы
		
		$tid = $timestamp->epoch;
		print "tid -> ".$tid."\n";
		$rolling_mill = '1';
=comment
		print 'tid -> '.$tid."\n";
		print 'heat -> '.$heat."\n";
		print 'grade -> '.$grade."\n";
		print 'standard -> '.$standard."\n";
		print 'recordid -> '.$recordid."\n";
		print 'SectionLeft -> '.$SectionLeft."\n";
		print 'StrengthClassLeft -> '.$StrengthClassLeft."\n";
		print 'TempLeft -> '.$TempLeft."\n";
		print 'SectionRight -> '.$SectionRight."\n";
		print 'StrengthClassRight -> '.$StrengthClassRight."\n";
		print 'TempRight -> '.$TempRight."\n";
		print 'rolling mill -> '.$rolling_mill."\n";
=cut

#		&mssql($timestamp, $heat, $grade, $standard);
		&mssql($tid, $heat, $grade, $StrengthClassLeft, $SectionLeft, $standard, $rolling_mill, $TempLeft, my $side = '0', $recordid);
		&mssql($tid, $heat, $grade, $StrengthClassRight, $SectionRight, $standard, $rolling_mill, $TempRight, my $side = '1', $recordid);


		sleep(1);
	}
}

sub mssql {
	my($tid, $heat, $grade, $StrengthClass, $section, $standard, $rolling_mill, $temperature, $side, $recordid) = @_;
#	print "\t help to me \n";
	print (join "  ", ($tid, $heat, $grade, $StrengthClass, $section, $standard, $rolling_mill, $temperature, $side, $recordid))."\n\n";
print "\n\n\n";

	my $host     = 'KRR-SQL-PACLX02';
	my $database = 'KRR-PA-MGT-QCRollingMill';

	my $DSN = "Driver={SQL Server};Server=$host;Database=$database;Trusted_Connection=yes";
	my $dbh = DBI->connect("dbi:ODBC:$DSN") || die "Error: $DBI::errstr"; 

	
	my $query = "UPDATE temperature_current SET heat='$heat', ".
				"grade='$grade', strength_class='$StrengthClass', ".
				"section=$section, standard='$standard', ".
				"temperature=$temperature where tid='$tid' ".
				"and rolling_mill=$rolling_mill and side=$side ".
				"IF \@\@ROWCOUNT=0 ".
				"INSERT INTO temperature_current (tid, [timestamp], ".
				"rolling_mill, heat, grade, strength_class, section, ".
				"standard, side, temperature) values ( ".
				"$tid, datediff(ss, '1970/01/01', GETDATE()), ".
				"$rolling_mill, '$heat', '$grade', '$StrengthClass', ".
				"$section, '$standard', $side, $temperature )";

=comment
	my $query = "UPDATE temperature_current SET heat='$heat', ".
				"grade='$grade', strength_class='$StrengthClass', ".
				"section=$section, standard='$standard', ".
				"temperature=$temperature where tid='$tid' ".
				"and rolling_mill=$rolling_mill and side=$side ".
				"IF \@\@ROWCOUNT=0 ".
				"INSERT INTO temperature_current (tid, [timestamp], ".
				"rolling_mill, heat, grade, strength_class, section, ".
				"standard, side, temperature) values ( ".
				"$tid, datediff(ss, '1970/01/01', GETDATE()), ".
				"$rolling_mill, '$heat', '$grade', '$StrengthClass', ".
				"$section, '$standard', $side, 555 )";
=cut
#	print $tid."\n";
#	print $query;

	my $sth = $dbh->prepare($query);
	$sth ->execute();
}
