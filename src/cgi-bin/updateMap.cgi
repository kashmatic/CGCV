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
use CGI;
use DBI;

use lib qw(PACKAGENAME);
use DB;

## Create CGI object
my $cgi = new CGI;

my $uploadDir = '_____UPLOAD_____';

my $file = $uploadDir.$cgi->param("dir")."/".$cgi->param("input");

open(FILE, $file);
my @load = <FILE>;
close(FILE);

my $response = join('',@load);

print $cgi->header;
print $response;
#print $cgi->end_html();



