#!/bin/sh
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
## Contact => biohelp@indiana.edu
## Written => 14th Nov 2008
##
##################################################################################

############################################################
##
## REQUIRED PARAMETERS
##
## These parameters must be set by the user before installation will proceed.
##
##
############################################################

## Support e-mail address
#
# CGCV advertises an address that CGCV users may contact for help. This
# allows your users questions to be directed to your support
# group.
#
# e.g. support_email="help@myorg.org"
#
support_email="kashi.revanna@unt.edu"

## Sendmail 
#
# Enter the location of the binary file for sendmail 
#
# e.g. sendmail="/usr/sbin/sendmail"
#
sendmail="/usr/sbin/sendmail"

## Base Apache URI
#
# Enter the base URI for the machine that will host CGCV. This variable is
# used to create the e-mail that is sent to users.
#
# e.g. apache_uri = "http://www.myorg.org"
#
apache_uri="http://cas-bioinfo.cas.unt.edu"

## BLASTALL Binary
#
# Enter the location of the StandAlone BLASTALL binary. This allows the
# program to locate the binary and execute when required
#
# e.g. blastall_binary="/downloads/software/blast-2.2.23/"
#
blastall_binary="/media/storage/packages/blast-2.2.23/"

## Upload Directory
#
# Enter the directory on your local filesystem. This directory is used to create
# directory to store uploaded file and supplementary files. 
#
# e.g. upload_directory = "/storage/tmp/"
#
upload_directory="/media/storage/www/tool/tmp/"

## Genomes Path
# 
# Enter the location of the bacterial & genomes. This directory is used to create
# files containing the genome, nucleotide and amino acid sequences. 
# 
# e.g. genomes_path="/storage/sequences/"
genomes_path="/media/storage/project/bioinfo/cgcv/"

############################################################
##
## OPTIONAL PARAMETERS
##
## These parameters have default values that will work if you follow
## the basic INSTALL steps. If you wish to connect to an existing
## database server, or specify a custom lifetime for results you may
## edit them below.
##
############################################################

## Database Username
#
# This is the username you use to connect to MySQL. The INSTALL doc
# gives instructions for creating a bov username.
#
database_username="cgcv"

## Database Password
#
# This is the password used to connecto to MySQL. If left blank, no
# password will be used. 
#
database_password=""

## Database Name
#
# This is the name of the MySQL database BOV will connect to. The
# INSTALL doc gives instructions for creating a database named
# microbial.
#
database_name="cgcv_database"

## Database Host
#
# The hostname of the machine where the database is located. By
# default this is the same machine where apache will run.
#
database_host="localhost"


## Results Lifetime
#
# This is the number of days results will be kept on the server. After
# this time, they will be deleted to save space. To never delete
# results, set this variable to 0. If the variable is not set to 0, 
# A cronjob will be created in the home directory, to delete the records from
# the database.
#
lifetime="60"

#####################  DO NOT EDIT BELOW THIS LINE!!!!!! ######################
###############################################################################

## Check for Required Parameters
if [ ! $support_email ] || [ ! $sendmail ] || [ ! $apache_uri ] || [ ! $blastall_binary ] || [ ! $upload_directory ] || [ ! $genomes_path ] || [ ! $database_username ] || [ ! $database_name ] || [ ! $database_host ]
then
        echo ".. Error: Required parameters are not provided."
        exit 1
fi

## Remove Directories
rm -rf htdocs
rm -rf cgi-bin
rm -rf bin

## Copy these directories from the src
cp -rp src/cgi-bin cgi-bin
cp -rp src/htdocs htdocs
cp -rp src/bin bin

## set variables
eukaryote="Eukaryotes/"
bacteria="Bacteria/" 
eukaryote_genomes=${genomes_path}${eukaryote}
bacteria_genomes=${genomes_path}${bacteria}

## Strings present in source files
old_name="_____DB_DATABASE_____"
old_host="_____DB_HOST_____"
old_username="_____DB_USER_____"
old_password="_____DB_PASSWORD_____"
old_directory="_____UPLOAD_____"
old_blastall="_____BLASTALL_____"
old_bact_genome="_____GENOME_DATA_____"
old_euk_genome="_____EUK_GENOME_____"
old_sendmail="_____SENDMAIL_____"
old_support_email="_____SUPPORT_EMAIL_____"
old_uri="_____URI_____"
old_lifetime="_____LIFETIME_____"

## Subroutine
parse(){
        sed -e s#$old_name#$database_name#g -e s#$old_host#$database_host#g -e s#$old_username#$database_username#g -e s#$old_password#$database_password#g -e s#$old_directory#$upload_directory#g -e s#$old_blastall#$blastall_binary#g -e s#$old_bact_genome#$bacteria_genomes#g -e s#$old_sendmail#$sendmail#g -e s#$old_support_email#$support_email#g -e s#$old_uri#$apache_uri#g -e s#$old_lifetime#$lifetime#g -e s#$old_euk_genome#$eukaryote_genomes#g -e s#old_bact_genome#$genomes_path#g -e s#$old_support_email#$support_email#g -e s#$old_name#$database_name#g -e s#$old_host#$database_host#g -e s#$old_username#$database_username#g -e s#$old_password#$database_password#g $1 > $1.$$
        mv $1.$$ $1
}

## Search and replace strings in the cgi-bin and htdocs directory.
find cgi-bin/ -type f | while read file
do
        parse $file
done

find bin/ -type f | while read file
do
        parse $file
done

## Change permissions
chmod -R 755 cgi-bin
chmod -R 755 htdocs
chmod -R 755 bin

## set soft link to upload directory
ln -s $upload_directory htdocs/tmp
