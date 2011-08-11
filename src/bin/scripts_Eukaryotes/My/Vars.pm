#!/usr/bin/perl
#########################################################
### Copyright 2008 The Trustees of Indiana University
###
### Licensed under the Apache License,  Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###      http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing,  software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
##########################################################

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

use vars qw(%euk);
my $dataDir = "_____EUK_GENOME_____";
my $main     = "taxid_orgname_Euk";
my $link     = "taxid_accno_Euk";
my $child    = "genedetails_Euk";
my $aaseqs   = "aaseqs_Euk";

%euk = (

    #---------------------------------------------------------------------------
    #  Data directory path
    #---------------------------------------------------------------------------
    dataDir => "$dataDir",

    #---------------------------------------------------------------------------
    #  FTP access information
    #---------------------------------------------------------------------------
    ftpLink   => "ftp.ensembl.org",
    directory => "/pub/current_",
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
    #  		Table name: taxid_orgname_Euk
    # 		+---------+--------------+------+-----+---------+-------+
    # 		| Field   | Type         | Null | Key | Default | Extra |
    # 		+---------+--------------+------+-----+---------+-------+
    # 		| taxid   | varchar(2)   | NO   | PRI | NULL    |       |
    # 		| orgname | varchar(100) | NO   |     | NULL    |       |
    # 		+---------+--------------+------+-----+---------+-------+
    #
    # 		linkTbl
    # 		Table name: taxid_accno_Euk
    # 		+-----------+--------------+------+-----+---------+-------+
    # 		| Field     | Type         | Null | Key | Default | Extra |
    # 		+-----------+--------------+------+-----+---------+-------+
    # 		| taxid     | varchar(2)   | NO   |     | NULL    |       |
    # 		| accno     | varchar(4)   | NO   |     | NULL    |       |
    # 		| orgname   | varchar(100) | YES  |     | NULL    |       |
    # 		| seqlength | int(11)      | YES  |     | NULL    |       |
    # 		+-----------+--------------+------+-----+---------+-------+
    #
    # 		childTbl
    # 		Table name: genedetails_Euk
    # 		+------------------+-------------+------+-----+---------+-------+
    # 		| Field            | Type        | Null | Key | Default | Extra |
    # 		+------------------+-------------+------+-----+---------+-------+
    # 		| accno            | varchar(4)  | NO   |     | NULL    |       |
    # 		| gene_id          | varchar(25) | YES  |     | NULL    |       |
    # 		| gene_start       | int(11)     | YES  |     | NULL    |       |
    # 		| gene_end         | int(11)     | YES  |     | NULL    |       |
    # 		| transcript_id    | varchar(25) | YES  |     | NULL    |       |
    # 		| transcript_start | int(11)     | YES  |     | NULL    |       |
    # 		| transcript_end   | int(11)     | YES  |     | NULL    |       |
    # 		| strand           | varchar(1)  | YES  |     | NULL    |       |
    # 		| description      | varchar(25) | YES  |     | NULL    |       |
    # 		+------------------+-------------+------+-----+---------+-------+
    #
    #---------------------------------------------------------------------------
    mainTbldrop  => "DROP TABLE IF EXISTS $main\;",
    linkTbldrop  => "DROP TABLE IF EXISTS $link\;",
    childTbldrop => "DROP TABLE IF EXISTS $child\;",

    mainTblcreate =>
"CREATE TABLE IF NOT EXISTS $main (taxid VARCHAR(2) NOT NULL PRIMARY KEY, orgname VARCHAR(100) NOT NULL)\;",
    linkTblcreate =>
"CREATE TABLE IF NOT EXISTS $link (taxid VARCHAR(2) NOT NULL, accno VARCHAR(4) NOT NULL, orgname VARCHAR(100), seqlength INT)\;",
    childTblcreate =>
"CREATE TABLE IF NOT EXISTS $child (accno VARCHAR(4) NOT NULL, protaccno VARCHAR(35), gene_id VARCHAR(35), gene_start INT, gene_end INT, transcript_id VARCHAR(35), transcript_start INT, transcript_end INT, strand VARCHAR(1), description VARCHAR(25))\;",

    mainTblLoad =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/main.csv\' INTO TABLE $main FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (taxid, orgname)\;",
    linkTblLoad =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/link.csv\' INTO TABLE $link FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (taxid, accno, orgname, seqlength)\;",
    childTblLoad =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/genedetails.csv\' INTO TABLE $child FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (accno, protaccno, gene_id, gene_start, gene_end, transcript_id, transcript_start, transcript_end, strand, description)\;",

    mainTblupdate =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/updatemain.csv\' REPLACE INTO TABLE $main FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (taxid, orgname)\;",
    mainTblupdate =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/updatemain.csv\' REPLACE INTO TABLE $link FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (taxid,  orgname)\;",
    childTblupdate =>
"LOAD DATA LOCAL INFILE \'$dataDir/tables/updategenedetails.csv\' REPLACE INTO TABLE $child FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\\n\' (orgname, chromosome_no, geneid, exon_num, gene_name, start, end, strand, protein_id)\;",

    #---------------------------------------------------------------------------
    #  MySQL statements to drop, create and update the AA sequence tables
    #
    #  Table name: aaseqs_Euk
    #  +-----------+-------------+------+-----+---------+
    #  | Field     | Type        | Null | Key | Default |
    #  +-----------+-------------+------+-----+---------+
    #  | protaccno | varchar(35) | NO   | PRI | NULL    |
    #  | sequence  | text        | YES  |     | NULL    |
    #  +-----------+-------------+------+-----+---------+
    #---------------------------------------------------------------------------
    aaSeqTbldrop => "DROP TABLE IF EXISTS $aaseqs\;",
    aaSeqTblcreate =>
"CREATE TABLE IF NOT EXISTS $aaseqs (protaccno VARCHAR(35) NOT NULL PRIMARY KEY, sequence TEXT)\;",
    aaSeqTblinsert => "INSERT INTO $aaseqs (protaccno, sequence) VALUES(?, ?)\;",
    aaSeqTblupdate => "UPDATE $aaseqs SET protaccno=?, sequence=?\;"
);
