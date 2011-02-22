#!/usr/bin/perl -w
#########################################################
## Copyright 2008 The Trustees of Indiana University
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#########################################################

#################################################################################
##
## Author  => Kashi V Revanna
## Company => The Center for Genomics and Bioinformatics
## Contact => biohelp@cgb.indiana.edu
## Written => 14th Nov 2008
##
#################################################################################

use strict;
use warnings;

## List of modules used ---------------------------------------------------------
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use HTML::Template;
use Bio::SeqIO;

use lib qw(PACKAGENAME);
use DB;
use Error;

## ------------------------------------------------------------------------------

## Create a CGI object
my $cgi = new CGI;

## variable used for display in the web page
my $contents;
my $uploadDir = "_____UPLOAD_____";

## Read the parameters from the form and save the file
my $dbtype = $cgi->param("dbtype");
my $evalue = $cgi->param("evalue");
my $email = $cgi->param("email");
my $program = $cgi->param("program");
my $getAll = $cgi->param("getAll") || 0;

## read the input file
my $createDir = getInput();

## To check for contents of file 
getInputType($createDir);

getGenomes($createDir);


## Redirect the page to display
my $location = '/cgi-bin/Euk_getProfile.cgi?dir='.$createDir.'&dbtype='.$dbtype.'&evalue='.$evalue;


$contents .= '
<!-- Waiting div to display the information -->
<div id="waiting">
<fieldset>
<p class="bodypara">
Please Wait.........<img src="/img/rotating_arrow.gif" onload="getOutput()">
<br>
We are processing your request. Thank you for your patience.
</div>';

my $ref_script = getScript();
my $parameters = getParameters();

my $script = $$ref_script;

$script .= '
	var xmlHttp;
	function getOutput(){
		//alert("this is test");
		xmlHttp = GetXmlHttpObject();
		if (xmlHttp==null) {
			alert ("Your browser does not support AJAX!");
			return;
		}
		// run the BLAST file with teh parameters provided below
		var url="/cgi-bin/Euk_runBlast.cgi?";
		url += "dbtype='.$dbtype.'";
		url += "&evalue='.$evalue.'";
		url += "&dir='.$createDir.'";
		url += "&email='.$email.'";
		url += "&para='.$parameters.'";
		url += "&program='.$program.'";
		xmlHttp.onreadystatechange=stateChanged;
		xmlHttp.open("GET",url,true);
		xmlHttp.send(null);
	}

	// Once the BLAST is completed, redirect to the Profile table
	function redirectThis() {
		//alert("we will be redirecting");
		window.location = "'.$location.'";
	}
	';


## HTML page
print $cgi->header;
my $template = HTML::Template->new(
	filename => "templates/main.tmpl");

$template -> param (TITLE => "Waiting" );
$template -> param (CONTENT => $contents );
$template -> param (SCRIPT => $script );

print $template->output;
print $cgi->end_html();
## end HTMl page

exit 0;


##################################################################################

sub getGenomes {
	my $createdDir = $uploadDir.shift;
	$createdDir .= '/selected';

	open(SEL, ">", $createdDir);


	if ($getAll == 1){
		print SEL "allseqs","\n";
		close (SEL);
		return;
	}

        my @db  = $cgi->param('s');
	my $listDb;

	if(scalar(@db) > 1){
		$listDb = '"';
		$listDb .= join('" OR taxid like "',@db); 
		$listDb .= '"';
	} else {
		my $s = join('', @db);
		$listDb .= '"'.$s.'"';
	}
	
	## Connect to the database
	my $accession;
	eval {
		$accession = DB->exec( "SELECT accno FROM taxid_accno_Euk WHERE taxid like $listDb");
	};
	displayErrorPage($@) if ($@);

	foreach (@$accession){
		print SEL @$_[0],"\n";
	}
	close(SEL);
}

##################################################################################
## Input - filename
## Requires - program chosen in the form
## Returns - none
## Implements 
## - validates the sequences
## - runs formatdb program on the sequences file

sub getInputType {
	## Path to the file
	my $infile = $uploadDir.shift;
	$infile .= '/inputFile';

	## Obtain the program form the form
	my $program = $cgi->param('program');

	## use perl module to create sequence objects
	my $in = Bio::SeqIO->new(-file => $infile, -format => 'Fasta')
		or displayErrorPage("The sequences provided are not in FASTA format");
	
	## Checking the sequences
	while ( my $seq = $in->next_seq() ){
		if (
			(
				(($seq->alphabet eq 'dna') || ($seq->alphabet eq 'rna')) &&
				(($program eq "blastp") || ($program eq "tblastn"))
			)
			||
			(
				($seq->alphabet eq 'protein') &&
				(($program eq "blastn") || ($program eq "blastx") || ($program eq "tblastx"))
			)
		)
		{
			## report error if the sequeces and program chosen dont match
			displayErrorPage("BLAST program chosen is not applicable to the submitted sequences");
		}
	}
}

##################################################################################
## Input - none
## Requires - form parameters like 'sequence', 'seqfile', 
## Returns - filename of the uploaded file
## Implements 
## - creates a file
## - stores the information to the file

sub getInput {
	
	## Reading form parameters
        my $sequence = $cgi->param('sequence');
	my $filename = $cgi->param('seqfile');

	## for unique name, digest the time and process id
	my $createUploadDir = time().$$;
	my $infile = $uploadDir.$createUploadDir;

	system("mkdir $infile");

	## Path to input file
	$infile .= '/inputFile';

	## Check if the parameters are provided
	## preference to uploaded file rather than typed in input sequence
	if ($filename){
		## Check of the filename is valid, if not give error
		if (checkFile($filename)){
			## Error to be displayed
			displayErrorPage("Conflicting Filename provided");
		}

		## Reading the uploaded file
		my $file = $cgi->upload('seqfile');

		## Storing the file
		open ( UPLOADFILE, ">$infile") or displayErrorPage("Unable to open the inputFile");
		binmode UPLOADFILE;
		while (<$file>)  {
			print UPLOADFILE;
		}
		close UPLOADFILE;

	} elsif ($sequence) {
		## If sequence was provided in the textbox
		open (FILE, ">$infile");
		print FILE  $sequence;
		close FILE;
	} else {
		## Error, if no sequence and file are provided
		displayErrorPage("Please submit the sequences' file or the sequences");
	}

	## Returns the file
	return $createUploadDir;
}

##################################################################################
## Input - filename
## Requires - none
## Returns - True (1) if good

sub checkFile {
	my $name = shift;
	if ($name =~ /^([-\@:\/\\\w.]+)$/) {
		return 0;
	} else {
		return 1;
}
							}
##################################################################################
sub getScript{
	my $script = '
		// Get the XmlHttpObject
		function GetXmlHttpObject() {
			var xmlHttp=null;
			try {
				// Firefox, Opera 8.0+, Safari
				xmlHttp=new XMLHttpRequest();
			}
			catch (e) {
				// Internet Explorer
				try {
					xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
				}
				catch (e) {
					xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
				}
			}
			return xmlHttp;
		}

		// On state change, include the information into the waiting div
		function stateChanged() {
			if (xmlHttp.readyState==4) {
				document.getElementById("waiting").innerHTML=xmlHttp.responseText;
				redirectThis();
			}
		}

	';
	return \$script;	
}
##################################################################################

sub getParameters {
	my $program = $cgi->param("program");

	my $para;

	## Filter 
	if ( $cgi->param("filter") ne 'T'){
		$para .= ' -F '.$cgi->param("filter");
	}
	
	## threhold for extending word hits
	if ($cgi->param("thresholdWord") != 0){
		if ($program eq "blastn"){
			$para .= ' -f '.$cgi->param("gapOpen");
		} else {
			$para .= ' -f '.$cgi->param("gapOpen");
		}
	}

	## perform gapped alignment
	if ($cgi->param("gappedAlignment") ne 'T'){
		if ($program ne 'tblastx'){
			$para .= ' -g '.$cgi->param("gappedAlignment");
		}
	}

	## query genetic code
	if ($cgi->param("geneticCode") != 1 ){
		if (($program eq 'blastx') || ($program eq 'tblastx')){
			$para .= ' -Q '.$cgi->param("geneticCode");	
		}
	}

	## matrix
	if ($cgi->param("matrix") ne 'BLOSUM62'){
		$para .= ' -M '.$cgi->param("matrix");
	}

	## word size
	if ($cgi->param("word") != 0){
		$para .= ' -W '.$cgi->param("word");
	}

	## effective length of database
	if ($cgi->param("databaseLength") != 0){
		$para .= ' -z '.$cgi->param("databaseLength");
	}

	## best hits to keep
	if ($cgi->param("bestHits") != 0){
		$para .= ' -K '.$cgi->param("bestHits");
	}

	## effectiv elength of search space
	if ($cgi->param("searchSpace") != 0){
		$para .= ' -Y '.$cgi->param("searchSpace");
	}

	## nucleotide query strand to use
	if ($cgi->param("nQueryStand") != 3){
		if(($program ne 'blastp') && ($program ne 'blastx')){
			$para .= ' -S '.$cgi->param("nQueryStand");
		}
	}

	## lowercase filtering
	if ($cgi->param("lowercaseFilter") ne 'F'){
		$para .= ' -U '.$cgi->param("lowercaseFilter");
	}
	
	## drop off value for ungapped extensions
	if ($cgi->param("dropoffUngapped") != 0){
		$para .= ' -y '.$cgi->param("dropoffUngapped");
	}

	## drop off value for gapped alignments
	if ($cgi->param("dropoffGapped") != 0){
		$para .= ' -X '.$cgi->param("dropoffGapped");
	}

	## drop off value for gapped alignments
	if ($cgi->param("dropoffFinal") != 0){
		$para .= ' -Z '.$cgi->param("dropoffFinal");
	}

	## activate megablast
	if ($cgi->param("megaBlast") ne 'F'){
		$para .= ' -n '.$cgi->param("megaBlast");
	}

	## frame shift penalty
	if ($cgi->param("frameShift") != 0){
		if (($program eq 'blastx') || ($program eq 'tblastn')){
			$para .= ' -w '.$cgi->param("frameShift");
		}
	}

	return $para;

}

exit;
1;

