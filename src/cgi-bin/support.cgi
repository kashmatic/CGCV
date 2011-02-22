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
<h4>The Center for Genomics and Bioinformatics</h4>
<p class="bodypara">
Please send comments and suggestions to : 
<a href="mailto:_____SUPPORT_EMAIL_____">_____SUPPORT_EMAIL_____</a>
</p>
';

## Create the HTML page and display
print $cgi->header;
my $template = HTML::Template->new(
        filename => "templates/main.tmpl");


if ($cgi->param('error')){
        my $error = '<fieldset>'
                        .'<legend background="red">'
                        .'Error'
                        .'</legend><p class="bodypara">'
                        .$cgi->param('error')
                        .'</fieldset><br>';
        $template -> param (ERROR => $error);
}


$template->param (TITLE => "GenomeView");
$template->param (CONTENT => $content);

print $template->output;
print $cgi->end_html();

exit;
1;


################################################################################
