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

use strict;

## list of modules used
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use DBI;

use lib qw(PACKAGENAME);
use DB;

## Create a CGI object
my $cgi = new CGI;

my $dataArray;
eval {
	$dataArray = DB->exec("SELECT accno, orgname FROM taxid_accno ORDER BY orgname ASC"); 
};
displayErrorPage($@) if($@);


## Page contents
## CHANGE next cgi page
my $content;
foreach (@$dataArray) {
	$content .= '<option value="'.@$_[0].'">'.@$_[1].'</option>';
}

my $description = '
<h4>Dynamic Gene Cluster Comparison in Prokaryotic Genomes</h4>
<p class="bodypara" align="justify">
Are you curious about how a <a href="/cgi-bin/about.cgi">gene
cluster</a> is conserved across other genomes? Use our
web-based <b>C</b>omparative <b>G</b>ene <b>C</b>luster <b>V</b>iewer (CGCV) 
to interactively visualize the conservation of your favorite gene
cluster against the available Bacterial genomes, via our novel
multi-genome browser. Step-by-step instructions are provided in the <a
href="/cgi-bin/tutorial.cgi">tutorial</a> page. Our
Bacterial sequence repository is synchronized with <a
href="ftp://ftp.ncbi.nih.gov/genbank/genomes/Bacteria">NCBI GenBank</a>
on a nightly basis thus guaranteeing access to the latest sequence data. 
View the <a href="demo.cgi">Update Report</a> to see the status of our repository. 
</p>
';

my $program = '
	<option>blastn</option>
	<option selected>blastp</option>
	<option>blastx</option>
	<option>tblastn</option>
	<option>tblastx</option>
	';

my $dbtype = '
	<option value="genomes">genome</option>
	<option value="geneseqs">gene</option>
	<option value="aaseqs" selected>protein</option>
	';


## Create the HTML page and display
print $cgi->header;
my $template = HTML::Template->new(
        filename => "templates/blast.tmpl");


if ($cgi->param('error')){
        my $error = '<fieldset>'
                        .'<p class="bodypara">Error<br>'
                        .$cgi->param('error')
                        .'</p></fieldset><br>';
        $template -> param (ERROR => $error);
}


$template->param (EXAMPLE => 'href="/cgcv/Phosphate_trans_and_reg.faa" title="Phosphate transport and regulation - gene cluster from Caulobacter crescentus CB15"');
$template->param (TITLE => "BLAST");
$template->param (ACTION => "doBlast.cgi");
$template->param (SIZE => "10");
$template->param (DESCRIPTION => $description);
$template->param (PROGRAM => $program);
$template->param (DBTYPE => $dbtype);
$template->param (CONTENT => $content);

print $template->output;
print $cgi->end_html();

sub displayErrorPage{
        ## Display error webpage  if the upload file is not a BLAST output file
        my $cgi = new CGI;
        my $content = '
      <h4>Error</h4>
      <p class="bodypara">Sorry, We have encountered an error. 
      Please contact the CGCV Developer Team at 
      <a href="mailto:Qunfeng.Dong@unt.edu">
      Qunfeng.Dong@unt.edu
      </a> with the message you have received below and a brief description of what led you to this problem. 
      We will be glad to make BOV better and better. <br>
      <br>
      Thank you, <br>
      <strong>CGCV Team.</strong>
      <br>
      </p>

      <p class="bodypara">
      Message:<br>
    ';
  
        $content .= '<span style="color:red;" class="bodypara">';
        $content .= shift;
        $content .= '</span>
    </p>';

  print $cgi->header;
        my $template =  HTML::Template->new(filename => "templates/main.tmpl");

  $template->param(TITLE => "ERROR");
        $template->param(CONTENT => $content);
        
  print $template->output;
        print $cgi->end_html();
        exit;
}

exit;
1;


################################################################################
