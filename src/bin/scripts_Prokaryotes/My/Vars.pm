#!/usr/bin/perl
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

#===============================================================================
#
#         FILE:  Vars.pm
#
#  DESCRIPTION:  Configuration file with all necessary Variables, FTP Access
#  				 information, File paths, MySQL database access details and
#  				 SQL statements
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Vivek Krishnakumar, <biohelp@cgb.indiana.edu>
#      COMPANY:  The Center for Genomics and Bioinformatics
#      VERSION:  1.0
#      CREATED:  10/17/08 16:28:40 EDT
#     REVISION:  ---
#===============================================================================

package My::Vars;
use strict;

use vars qw(%bact);
my $dataDir  = "_____GENOME_DATA_____";
my $main     = "taxid_accno";
my $child    = "genedetails";
my $geneseqs = "geneseqs";
my $aaseqs   = "aaseqs";

%bact = (

    #---------------------------------------------------------------------------
    #  Data and Script direcetory paths
    #---------------------------------------------------------------------------
    dataDir => "$dataDir",

    #---------------------------------------------------------------------------
    #  FTP access information
    #---------------------------------------------------------------------------
    ftpLink   => "ftp.ncbi.nih.gov",
    directory => "genbank/genomes/Bacteria",
    uname     => "anonymous",
    passwd    => '_____SUPPORT_EMAIL_____',

    #---------------------------------------------------------------------------
    #  Database access details
    #---------------------------------------------------------------------------
    dbname   => "_____DB_DATABASE_____",
    host     => "_____DB_HOST_____",
    dbuname  => "_____DB_USER_____",
    dbpasswd => "_____DB_PASSWORD_____",

    #---------------------------------------------------------------------------
    #  MySQl statements to drop, create and update the tables:
    #
    #  		mainTbl
    #  		Table name: taxid_accno
    #  		+-----------+---------------+------+-----+---------+
    #  		| Field     | Type          | Null | Key | Default |
    #  		+-----------+---------------+------+-----+---------+
    #  		| taxid     | int(11)       | NO   |     | NULL    |
    #  		| accno     | varchar(12)   | NO   | PRI | NULL    |
    #  		| orgname   | varchar(1000) | YES  |     | NULL    |
    #  		| seqlength | int(11)       | YES  |     | NULL    |
    #  		+-----------+---------------+------+-----+---------+
    #
    #  		childTbl
    #  		Table name: genedetails
    #  		+-------------+---------------+------+-----+---------+
    #  		| Field       | Type          | Null | Key | Default |
    #  		+-------------+---------------+------+-----+---------+
    #  		| accno       | varchar(12)   | NO   |     | NULL    |
    #  		| protaccno   | varchar(12)   | NO   |     | NULL    |
    #  		| geneid      | int(11)       | YES  | PRI | NULL    |
    #  		| locus       | varchar(15)   | YES  |     | NULL    |
    #  		| synonym     | varchar(5)    | YES  |     | NULL    |
    #  		| start       | int(11)       | YES  |     | NULL    |
    #  		| end         | int(11)       | YES  |     | NULL    |
    #  		| strand      | varchar(1)    | YES  |     | NULL    |
    #  		| description | varchar(5000) | YES  |     | NULL    |
    #  		+-------------+---------------+------+-----+---------+
    #---------------------------------------------------------------------------
    mainTbldrop  => "DROP TABLE IF EXISTS $main\;",
    childTbldrop => "DROP TABLE IF EXISTS $child\;",

    mainTblcreate =>
"CREATE TABLE IF NOT EXISTS $main (taxid INT NOT NULL, accno VARCHAR(12) NOT NULL PRIMARY KEY, orgname VARCHAR(1000), seqlength INT)\;",
    childTblcreate =>
"CREATE TABLE IF NOT EXISTS $child (accno VARCHAR(15) NOT NULL, protaccno VARCHAR(15), geneid INT PRIMARY KEY, locus VARCHAR(15), synonym VARCHAR(5), start INT, end INT, strand VARCHAR(1), description VARCHAR(5000), INDEX(accno), INDEX(protaccno))\;",

    mainTblLoad =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/main.tab\' INTO TABLE $main FIELDS TERMINATED BY \'\\t\' LINES TERMINATED BY \'\\n\' (taxid, accno, orgname, seqlength)\;",
    childTblLoad =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/child.tab\' INTO TABLE $child FIELDS TERMINATED BY \'\\t\' LINES TERMINATED BY \'\\n\' (accno, protaccno, geneid, locus, synonym, start, end, strand, description)\;",

    mainTblupdate =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/updatemain.tab\' REPLACE INTO TABLE $main FIELDS TERMINATED BY \'\\t\' LINES TERMINATED BY \'\\n\' (taxid, accno, orgname, seqlength)\;",
    childTblupdate =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/updatechild.tab\' REPLACE INTO TABLE $child FIELDS TERMINATED BY \'\\t\' LINES TERMINATED BY \'\\n\' (accno, protaccno, geneid, locus, synonym, start, end, strand, description)\;",

    #---------------------------------------------------------------------------
    #  MySQL statements to drop, create and update the NT sequence tables
    #
    #  Table name: geneseqs
    #  +----------+-------------+------+-----+---------+
    #  | Field    | Type        | Null | Key | Default |
    #  +----------+-------------+------+-----+---------+
    #  | geneid   | varchar(15) | NO   | PRI | NULL    |
    #  | sequence | text        | YES  |     | NULL    |
    #  +----------+-------------+------+-----+---------+
    #---------------------------------------------------------------------------
    ntSeqTbldrop => "DROP TABLE IF EXISTS $geneseqs\;",
    ntSeqTblcreate =>
"CREATE TABLE IF NOT EXISTS $geneseqs (geneid VARCHAR(15) NOT NULL PRIMARY KEY, sequence TEXT)\;",
    ntSeqTblinsert => "INSERT INTO $geneseqs (geneid, sequence) VALUES(?, ?)\;",
    ntSeqTblupdate => "UPDATE $geneseqs SET sequence=? WHERE geneid=?\;",

    #---------------------------------------------------------------------------
    #  MySQL statements to drop, create and update the AA sequence tables
    #
    #  Table name: aaseqs
    #  +-----------+-------------+------+-----+---------+
    #  | Field     | Type        | Null | Key | Default |
    #  +-----------+-------------+------+-----+---------+
    #  | protaccno | varchar(15) | NO   | PRI | NULL    |
    #  | sequence  | text        | YES  |     | NULL    |
    #  +-----------+-------------+------+-----+---------+
    #---------------------------------------------------------------------------
    aaSeqTbldrop => "DROP TABLE IF EXISTS $aaseqs\;",
    aaSeqTblcreate =>
"CREATE TABLE IF NOT EXISTS $aaseqs (protaccno VARCHAR(15) NOT NULL PRIMARY KEY, sequence TEXT)\;",
    aaSeqTblinsert => "INSERT INTO $aaseqs (protaccno, sequence) VALUES(?, ?)\;",
    aaSeqTblupdate => "UPDATE $aaseqs SET sequence=? WHERE protaccno=?\;"
);
