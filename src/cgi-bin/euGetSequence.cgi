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

## Modules required
use CGI;
use strict;
use Bio::SearchIO;
use Bio::SeqIO;
use CGI::Carp qw(fatalsToBrowser);
use POSIX qw(floor ceil);
use Math::Round;
use DBI;
use HTML::Template;

my $cgi = new CGI;

use lib qw(PACKAGENAME);
use DB;

my $uploadDir = "_____UPLOAD_____";

my $geneid = $cgi->param("geneid");
my $genome = $cgi->param("genome");
my $protaccno = $cgi->param("protaccno");
my $dir = $cgi->param("dir");

my $content;

my $org;
my $length;

my $array = DB->exec("Select orgname, seqlength from taxid_accno_Euk where accno like ?",[$genome]);
foreach (@$array){
	$org = @$_[0];
	$length = @$_[1];
}

my $locus;
my $synonym;
my $start;
my $end;
my $strand;
my $description;

my $details = DB->exec("Select distinct gene_start, gene_end, strand, description from genedetails_Euk where gene_id like ?",[$geneid]);

foreach (@$details){
	$start = @$_[0];
	$end = @$_[1];
	$strand = @$_[2];
	$description = @$_[3];
}


$content .= '
<h4>Gene Details</h4>

<table border="0px" width="100%" class="bodypara">

<tr>
<th width="200px"></th>
<th></th>

<tr>
<td>Organism name:</td><td>'.$org.'</td>
</tr>

<tr>
<td>Description:</td><td>'.$description.'</td>
</tr>

<tr>
<td>Start:</td><td>'.$start.'</td>
</tr>

<tr>
<td>End:</td><td>'.$end.'</td>
</tr>

<tr>
<td>Gene length:</td><td>';

$content .= $end - $start;

$content .= '</td>
</tr>

<tr>
<td>Strand:</td><td>'.$strand.'</td>
</tr>
</table>
<br>

<!--
<span class="bodypara">Gene sequence:</span>
<pre>$gene</pre>


<span class="bodypara">Protein sequence:</span>
<pre>$amino</pre>
-->

';

print $cgi->header;
my $template = HTML::Template->new(             
        filename => "templates/main.tmpl");
$template->param (TITLE => "Details");
$template->param (CONTENT => $content);

print $template->output;
print $cgi->end_html();
## ENDof File

