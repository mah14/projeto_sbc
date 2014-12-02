#! /usr/bin/perl


open($file_professors, "<",'lattes_out/sbc-membros.ris')
	or die "não foi possivel abrir o arquivo";
open($file_proj, "<",'sbc.owl')
	or die "não foi possivel abrir o arquivo";
open($file_out, ">",'populado.owl')
	or die "não foi possivel abrir o arquivo";
open($file_publications, "<", 'lattes_out/sbc-publicacoes.ris')
	or die "não foi possivel abrir o arquivo";

# constant strings
$indent = "    ";
$new_ln = "\n";
$end_doc = '</rdf:RDF>'.$new_ln;
$about_prefix = '<owl:NamedIndividual rdf:about="&renata;FOAF-modified#';
$resource_prefix = ' rdf:resource="&renata;FOAF-modified';
$data_prop_prefix = 'renata:FOAF-modified';

#global data structures
%peopleNames;
%publishersNames;
%universitiesNames;

#########################################################################################
#											#
#			Individual Constructors						#
#											#
#########################################################################################

sub newEntry{
	my $label = "@_";
	chomp($label);
	$label =~ s/^\s(.*)/$1/;
	$label =~ s/\s+/_/g;
	my $txt = $new_ln.'<!-- http://www.ime.usp.br/~renata/FOAF-modified#'."@_".' -->'.$new_ln.$new_ln;
	$txt = $txt.$about_prefix.$label.'">'.$new_ln;
#	<owl:NamedIndividual rdf:about="&renata;FOAF-modified#Arnaldo_Mandel">
}

sub class{
	return '<rdf:type'.$resource_prefix."@_".'"/>'.$new_ln;
#       <rdf:type rdf:resource="&renata;FOAF-modifiedPerson"/>
}

sub stringDataProps{
	my $txt='';
	if (@_ == undef){ return $txt;}
	my %hash = @_;
	foreach my $key ( keys %hash ){
		my $value = $hash{$key};
		chomp($value);
		$value =~ s/\s/_/g;
		$txt = $txt.'<'.$key.'>'.$value.'</'.$key.'>'.$new_ln;
#	        <renata:FOAF-modifiedfirstName>Arnaldo</renata:FOAF-modifiedfirstName>
   	}
	return $txt;
}

sub intDataProps{
	my $txt="";
	if (@_ == undef){ return $txt;}
	my %hash = @_;
	foreach my $key ( keys %hash ){
		my $value = $hash{$key};
		my $value = $hash{$key};
		$value =~ s/\s/_/g;
		$txt = $txt.'<'.$key.' rdf:datatype="&xsd;integer">'.$value.'</'.$key.'>'.$new_ln;
#		 <studentFrom rdf:datatype="&xsd;integer">1970</studentFrom>

   	}
	return $txt;
}

sub relationProps{
	my $txt="";
	if (@_ == undef){ return $txt;}
	my %hash = @_;
	foreach my $key ( keys %hash ){
		my $value = $hash{$key};
		chomp($value);
		$value =~ s/\s/_/g;
		$txt = $txt.'<'.$key.$resource_prefix.'#'.$value.'"/>'.$new_ln;
#	        <professorAt rdf:resource="&renata;FOAF-modified#Brasil"/>
   	}
	return $txt;
}

sub indent{
	my @txt = split(/\n/ , $_[0]);
	my $s = 4;
	my $e = @txt-2;
	for (@txt){
		$_ = $_."\n".$indent;
	}
	for my $i( $s...$e){
		$txt[$i] = $indent.$txt[$i];
	}
	return @txt;
}

sub endEntry {
	return '</owl:NamedIndividual>'.$new_ln.$new_ln.$new_ln;
}


#########################################################################################
#											#
#			getters of individuals data					#
#											#
#########################################################################################

sub thesisTitle{
	$t = $_[0];
	if ($t =~ s/\s*Título:\s*(.*)/$1/) {
		$t =~ s/(.*),\s*Ano.*/$1/;
		#print $t."\n";
		return $t; 
	}
}
sub supervisor{
	my @thesis = split (/\./,$_[0]);
	for my $t (@thesis) {
		if ($t =~ s/\s*Orientador:\s*(.*)/$1/) {
			$t =~ s/\s*com período.*//;
			chomp $t;
			return $t;
		}
	}
	return undef;
}
sub name{
	if( s/NOME\s*-\s*(.*)/$1/) { #find name
		return split(/\s+/);
	}
	return undef;
}

sub nameProps{
	return (
		'renata:FOAF-modifiedfirstName' => $_[0],
		'renata:FOAF-modifiedfamilyName' => $_[-1],
	);
}

sub citation{
	my $cit = <$file_professors>;
	if( $cit =~ s/CITA\s+-\s+(.*)/$1/){
		return split(/;/, $cit);
	}
}

sub startDate{
	my $date = "@_";
	if( $date =~ s/FO[0-9]a\s*-\s*(.*)/$1/) { # start year
		return $date;
	}
	return 0;
}
sub endDate{
	my $date = "@_";
	if( $date =~ s/FO[0-9]b\s*-\s*(.*)/$1/) { # end year
		return $date;
	}
	return 0;
}
sub gradLevel{
	my $level = "@_";
	if( $level =~ s/FO[0-9]c\s*-\s*(.*)/$1/) { #graduation level(undergraduate/ masters/ doctorade)
		if($level =~ m/\s*Doutorado.*/i){
			return "doctorateStudent";}
		elsif($level =~ m/\s*Mestrado.*/i){
			return "mastersStudent";}
		elsif($level =~ m/\s*Graduação.*/i){
			return "undergraduateStudent";}
	}
	return 0;
}
sub university{
	my $uni = "@_";
	if($uni =~ s/FO[0-9]d\s*-\s*(.*)/$1/) { # University name	
		@uni = split(/\s*,\s*/, $uni);
		chomp(@uni);
		return @uni;
	} #spli
	return undef;	
}

sub thesisInfo{
	my $d = $_[0];
	my $t = $_[1];
	if($t =~ s/FO[0-9]e\s+-\s+(.*)/$1/) { # thesis data
		my $title = thesisTitle $t;
		my $new = newEntry($title).class("#Thesis").stringDataProps("documentTitle"=> $title).intDataProps("publicationYear" => $d);
		if( my $supervisor = supervisor $t) {
			#$supervisor = addPerson($supervisor);
			$peopleNames{ $supervisor} = 1;
			my $props = relationProps(('supervisedBy'=>$supervisor, $data_prop_prefix."made" => $title));
			print $file_out indent( $new.relationProps('supervisedBy'=>$supervisor).endEntry);
			return $props;
		}
	}
	return "";
}

sub nextLine{
	my $f = $_[0]; 
	my $line = <$f>;
	chomp $line;
	return $line;
}

sub studyHistoric{
	my $hist = "";
	while(my $line = (nextLine $file_professors)){
		if ( my $temp = startDate $line) { 				# beginning of a graduation register
			$startDate = $temp; 					# first line is the admission year
		 	$endDate = endDate( nextLine $file_professors); 	# year of graduation
			$gradLevel = gradLevel( nextLine $file_professors);	# graduation type
			if ($gradLevel){					# should be masters, doctorade or undergraduate
				@uni = university( nextLine $file_professors); # @uni = {name, country}
				addUni(@uni);
				$relProps{$gradLevel."At"} = $uni[0];		#ex Person doctoradeAt Organization
				$date{$gradLevel."From"} = $startDate;		#ex Person doctoradeFrom Organization
				$date{$gradLevel."To"} = $endDate;		#ex Person doctoradeTo Organization
				$hist = $hist.( thesisInfo( $endDate, nextLine $file_professors));
			}
		}	
		if ($line =~ m/TY\s*-\s*MEMBRO.*/) { 
			$hist = $hist.( intDataProps %date).( relationProps %relProps);
			print $hist;
			return $hist;
		}
	}
	return $hist.( intDataProps %date).(relationProps %relProps);
}

sub isNewProfessorEntry{
#	if( $_[0] =~ m/TY\s*-\s*MEMBRO/) {
	if( $_[0] =~ m/NOME\s*-.*/) {
		return 1;
	}
	else {
		return 0;
	}
}

sub keepName{
	$p = $_[0];
	$p = lc($p);
	my @name = split(/ /,$p);
	foreach (@name) {
		s/^(.)/\U$1/;
	}
	$peopleNames{"@name"} = 1;
}

sub findFullNames{
	my @fullNames;
	my @citations = split(/;/, $_[0]);	#split per author reference
#	print "citations: @citations\n";
	foreach( @citations) { 		
		chomp;
		my $t = $_;
		$t =~ s/.//;
		my @cit = split(/[, ]/, $t);	#split last name from rest of names
		$t = @cit[0]; 			#put name in sequential order
		@cit[0] = @cit[-1];
		@cit[-1] = $t;
		foreach my $name ( keys %peopleNames){
			if ( $name =~ m/.*\s*$cit[-1]/i){ 		#try to match last name
				if ($name =~ m/$cit[0].*/i or $name =~ m/.*$cit[1].*/i){ #try to match first or second name
					push( @fullNames, $name);		#found author
				}
			}
		} 
	}
	return @fullNames;
}

sub populateProfessors{
	print "adding professors\n"; 
	while( <$file_professors>){
		if( isNewProfessorEntry($_)){
			my @name = name($_);		#get name
			keepName("@name");
			my $new = newEntry("@name").class ('Person'). stringDataProps( nameProps @name).studyHistoric.relationProps("professorAt" => "IME").endEntry;
			print $file_out $new;	
			print $file_out indent($new);
			print $file_out $new;
		}
	}
	close($file_professors);
	print "finished adding professors\n";
}

sub authors{
	my $l = "@_";
	my @authors;
	if ($l =~ s/AU\s*-\s*(.*)/$1/){
		@authors = findFullNames($l);
	}
	return @authors;
}

#receives where it was published and line to extract title from
sub pubTitle{	
	my $title = $_[0];
	if ($title =~ s/T1\s*-\s*(.*)/$1/){
		return $title;
	}
	return "";
}

sub publisherType{
	if ($_[0] =~ s/^TY\s*-\s*(.*)/$1/){
		if ($_[0] =~ m/CONF\s+/){
			return "Conference";
		}
		if ($_[0] =~ m/MGZN\s+/){
			return "Magazine";
		}
	}
	return "";
}

sub publisherName{
	my $name = $_[0];
	if ($name =~ s/TI\s*-\s*(.)/$1/) {
		return $name;
	}
	return "";
}

sub publicationYear{
	if( $_[0] =~ s/PY\s*-\s*(.*)/$1/) {
		return $_[0];
	}
	return 0;
}

sub addPublisher{
	$name = $_[0];
	$type = $_[1];
	if( !$universitiesNames{$name} ) {
		print $file_out indent( newEntry($name).class("#".$type).stringDataProps(($data_prop_prefix."name") => $name).endEntry);
		$universitiesNames{$names} = 1;
	}
}

sub addPublications{
	print "adding publications\n";
	while( my $l = <$file_publications>) {
		my $publisherType = publisherType $l;
		if (!$publisherType) { next; }  #conference or magazine	
		my @authors = authors( nextLine $file_publications);
		my $pub_title = pubTitle( nextLine $file_publications);
		my $publisherName = publisherName( nextLine $file_publications);
		#print "name: $publisherName    -    type: $publisherType\n";
		addPublisher( $publisherName, $publisherType);
		my $new = newEntry($pub_title).class( '#Article');
		$new = $new.relationProps( "publishedAt" => $publisherName);
		$new = $new.stringDataProps( 'documentTitle' => "$pub_title");
		foreach my $a( @authors){
			$new = $new.relationProps(( $data_prop_prefix."maker") => $a);
		}
		while ($l = nextLine $file_publications){
			my $publicationYear = publicationYear($l);
			if( $publicationYear) {
				$new = $new.intDataProps("publicationYear" => $publicationYear);
				last;
			}
		}
		print $file_out indent($new.endEntry);
	}
	close $file_publications;
	print "finished adding publications\n"
}

sub addUni{
	my %props;
	if (scalar @_ > 1){
		%props = ('situatedAt'=> $_[-1]);
	}
	if (@_) {
		if (!$universitiesNames{$uni[0]}){
			$universitiesNames{$uni[0]} = 1;
			print $file_out indent( newEntry ($uni[0]).class("#University").relationProps( %props).endEntry );
		}
	}
}

sub copyLines {
	print "copying project file\n";
	while( <$file_proj> ) {
		if( $_ =~ m/<\/rdf:RDF>/){
			break;
		}
		else{
			print $file_out $_;
		}
		#$line = <$file_proj>;
	}
	close $file_proj;
	print "finished copying file\n";
}

copyLines; #copy ontology definition from file
print $file_out indent(newEntry("IME").class("#Department").relationProps("partOf" => "Universidade de São Paulo").stringDataProps("name" => "Instituto de Matemática e Estatística").endEntry);
populateProfessors; 
#foreach my $k ( keys %peopleNames){
#	print $k.new_ln;}
addPublications;
print $file_out $end_doc;

