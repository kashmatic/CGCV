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

## list of modules used
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use DBI;

use lib qw(PACKAGENAME);
use DB;
use Error;

## Create a CGI object
my $cgi = new CGI;

my $dataArray;
eval {
	$dataArray = DB->exec("SELECT taxid, orgname FROM taxid_orgname_Euk ORDER BY orgname ASC");
};
displayErrorPage($@) if($@);

## Page contents
## CHANGE next cgi page
my $content;
foreach (@$dataArray) {
        $content .= '<option value="'.@$_[0].'">'.@$_[1].'</option>';
}


my $description = '
<h4>Dynamic Gene Cluster Comparison in Eukaryotic Genomes</h4>
<p class="bodypara" align="justify">
Are you curious how a 
<a href="faq.cgi" target="_blank">gene cluster</a>
is conserved across other eukaryotic genomes? Use our web-based Comparative Gene Cluster Viewer (CGCV) to interactively visualize the conservation of your favorite gene cluster against protein sequences from the selected species via our novel multi-genome browser. Step-by-step instructions are provided in the 
<a href="tutorial.cgi" target="_blank">tutorial</a>
page.
</p>
';

my $program = '
	<option> blastp</option>
	<option> blastx</option>
	';

my $dbtype = '
	<option value = "aaseqs"> protein </option>
	';
			
## Create the HTML page and display
print $cgi->header;
my $template = HTML::Template->new(
        filename => "templates/blast.tmpl");


$template->param (EXAMPLE => 'href="/HoxACluster-HS-Chr7" title="HoxA gene cluster from Human Chromosome 7"');
$template->param (SIZE => "6");
$template->param (ACTION => "Euk_doBlast.cgi");
$template->param (TITLE => "BLAST");
$template->param (DESCRIPTION => $description);
$template->param (PROGRAM => $program);
$template->param (DBTYPE => $dbtype);
$template->param (CONTENT => $content);

print $template->output;
print $cgi->end_html();

exit;
1;


################################################################################
