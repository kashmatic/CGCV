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
##################################################################################


########################################################################
## Modules required
use CGI;
use strict;
use Bio::SearchIO;
use Bio::SeqIO;
use CGI::Carp qw(fatalsToBrowser);
use POSIX qw(floor ceil);
use Math::Round;
use HTML::Template;
use DBI;

my $cgi = new CGI;

use lib qw(PACKAGENAME);
use DB;

my $uploadDir = "_____UPLOAD_____";

my $query = $cgi->param("query");
my $hitName = $cgi->param("hit");
my $start = $cgi->param("start");
my $end = $cgi->param("end");
my $dir = $cgi->param("dir");
my $dbtype = $cgi->param("dbtype");

my $content = '

<h4>
Blast Details
</h4>
';

my $blastFile = $uploadDir.$dir.'/blastOutput';
my $readBlastOutput = Bio::SearchIO->new('-file' => $blastFile,'-format'=>"blast");
my $alignment;

while( my $result = $readBlastOutput->next_result()){
	next if ($result->query_name ne $query);
	while( my $hit = $result->next_hit()){
		next if ($hit->accession ne $hitName);
		while (my $hsp = $hit->next_hsp()){
			next if (($hsp->start('query') ne $start) && ($hsp->end('query') ne $end));

			## Contents to be displayed when cicked on view alignment
			my $hitDescription = ($dbtype eq "geneseqs") ? $hit->name : $hit->description;
			$alignment = "<pre>".
				"<b>Query</b>\t= ".	$result->query_name." ".$result->query_description." (length: ".$result->query_length.")".
				"<br>".
				"<b>Hit</b>\t= ".	$hitDescription." (length: ".$hit->length.") ".
				"</pre><pre>".
				"<b>Score</b>\t= ".	$hsp->bits.
				" <b>bits</b> (".	$hsp->score.
				")<br>".
				"<b>E-Value</b>\t= ".	$hsp->evalue. 
				"<br>".
				"<b>Identities</b>\t= ".	$hsp->num_identical . "/".$hsp->hsp_length. 
				" (".floor(($hsp->num_identical / $hsp->hsp_length) * 100).
				"%)<br>";
			
			if ($hsp->num_conserved)
			{
				$alignment .=
				    "<b>Positives</b>\t= "
				  . $hsp->num_conserved . "/"
				  . $hsp->hsp_length . " ("
				  . floor(($hsp->num_conserved / $hsp->hsp_length) * 100)
				  . "%)<br>";
			}

			if ($hsp->gaps)
			{
				$alignment .= "<b>Gaps</b>\t= "
				  . $hsp->gaps . "/"
				  . $hsp->hsp_length . "  ("
				  . floor(($hsp->gaps / $hsp->hsp_length) * 100)
				  . "%)<br>";
			}
			$alignment .= "<b>Strand</b>\t=";
			$alignment .=
			  ($hsp->start('query') < $hsp->end('query'))
			  ? " Plus /"
			  : " Minus /";
			$alignment .=
			  ($hsp->start('hit') < $hsp->end('hit'))
			  ? " Plus<br>"
			  : " Minus<br>";
			$alignment .= "</pre>";
			
			my $w    = 0;
			my $qs   = $hsp->start('query');
			my $qe   = $hsp->end('query');
			my $hs   = $hsp->start('hit');
			my $he   = $hsp->end('hit');
			my $x    = $hsp->hsp_length;
			my $tab;

			if (
			($qs>99999) or
			($qe>99999) or
			($hs>99999) or
			($he>99999))
			{
				$tab = "\t\t";
			}
			else
			{
				$tab = "\t";
			}
			my $htab=$tab;
			my $qtab=$tab;
			
			my $queryseq=$hsp->query_string;
			my $hitseq=$hsp->hit_string;
			my $homology=$hsp->homology_string;

			while ($x >= 0)
			{
				if ($hs>99999){$htab="\t"};
				if ($qs>99999){$qtab="\t"};
				my $q_end = $x < 60 ? $qs + $x - 1 : $qs + 60 - 1;
				my $h_end =
				  $x < 60
				  ? ($he > $hs) ? $hs + $x - 1 : $hs - $x + 1
				  : ($he > $hs)
				  ? $hs + 60 - 1
				  : $hs - 60 + 1;
				my $qdash = (substr($queryseq, $w, 60) =~ tr/-//);
				$q_end -= $qdash;
				my $hdash = (substr($hitseq, $w, 60) =~ tr/-//);
				$h_end = ($he > $hs) ? $h_end - $hdash : $h_end + $hdash;
				$alignment .=
				    "<pre>Query   : " . $qs . $qtab
				  . substr($queryseq, $w, 60) . "\t"
				  . $q_end . "<br>" . "\t"
				  . $tab
				  . substr($homology, $w, 60) . "<br>"
				  . "Sbjct   : "
				  . $hs
				  . $htab
				  . substr($hitseq, $w, 60) . "\t"
				  . $h_end
				  . "</pre>";
				$x -= 60;
				$w += 60;
				$qs = $q_end + 1;
				$hs = ($he > $hs) ? $h_end + 1 : $h_end - 1;
			}    ##ENDwhile
			
			
		}    ## ENDwhile

	}
}

## ENDsubroutine showControlPanel

$content .= $alignment.'
	<span class="bodypara">
	<a href="/tmp/'.$dir.'/blastOutput">Download complete BLAST output</a>
	</span>
	
	';

print $cgi->header;
my $template = HTML::Template->new(             
        filename => "templates/main.tmpl");
$template->param (TITLE => "Details");
$template->param (CONTENT => $content );

print $template->output;
print $cgi->end_html();
## ENDof File

