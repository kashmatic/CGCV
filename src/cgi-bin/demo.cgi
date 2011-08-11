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

## Create a CGI object
my $cgi = new CGI;

## Page contents
my $content = '
<h4>Showcases of CGCV</h4>
<p class="bodypara" align="justify">
If you want to get a taste of CGCV, check out the following links to see how we have applied CGCV to both Prokaryotic and Eukaryotic datasets.
</p>
<ul class="bodypara">
<li>Click <a href="/cgi-bin/cgcv/proForm.cgi">here</a> to compare gene clusters in Prokaryotic genomes</li>
<li>Click <a href="/cgi-bin/cgcv/euForm.cgi">here</a> to compare gene clusters in Eukaryotic genomes</li>
</ul>
<p class="bodypara" align="justify">
We are committed to maintaining the above two "showcase" servers up to date. However, if you would like to use CGCV on your own data set, you can
download the entire system from the <a href="/cgi-bin/software.cgi">software</a> page. (Refer to the accompanying documentation files for detailed information
on setting up the system.)
</p>
';

## Create the HTML page and display
print $cgi->header;
my $template = HTML::Template->new(
        filename => "templates/main.tmpl");

$template->param (TITLE => "GenomeView");
$template->param (CONTENT => $content);

print $template->output;
print $cgi->end_html();

exit;
1;


################################################################################
