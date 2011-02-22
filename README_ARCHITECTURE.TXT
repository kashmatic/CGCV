#########################################################
## Copyright 2008 The Trustees of Indiana University
##
## Licensed under the Apache License,  Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,  software
## distributed under the License is distributed on an "AS IS" BASIS, 
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#########################################################

This document provides an overview of the architectural aspects of CGCV and is written for the purpose of providing the inner details about the design of this tool.

* How is the Phylogenetic Profiling table generated?

The Phylogenetic profile is generated from the BLASTALL output, where the input sequence(s) is/are blasted against the Genome, Nucleotide 
and Protein sequence database. The number of significant hits (evalue less than cut-off evalue provided in the sequence submit form)  are
displayed in the table implying that this gene has similarity with the sequence. If there is no significant hit, "0" is seen in the table.
Each row in the table is Genome and each column is the input sequence.

* How is the Image created?

The GD image library is used to generate the image dynamically for each request. The methods colorAllocate, line, filledRectangle and filledPolygon 
are used to generate the images. For more information, refer to http://search.cpan.org/~lds/GD-2.41/GD.pm

* Procedure followed:
  
  -MySQL is used to manage genome data, as well as persist intermediate and final results for user requests.

  -The images are created and loaded as a vertical list. The generated images display information corresponding to the entire span of the genome under
   consideration.

  -When a user manipulates the view of a particular genome, an AJAX call is used so only that image is redrawn. When comparing multiple genomes, 
   this leads to a reduction in load time proportional to the number of genomes.

  -HTML image maps are used to identify the positions of various genes in the image. These maps are updated by the same AJAX mechanism everytime the image
   is manipulated using the controls. The maps provide the user with the ability to mouse over the images and find out information corresponding to a 
   particular gene of interest.

-----------------------
MySQL Database schema
-----------------------

PROKARYOTES

taxid_accno
------------
Table that links the accession numbers with the organism names and the lengths of the sequences
+-----------+---------------+------+-----+---------+-------+
| Field     | Type          | Null | Key | Default | Extra |
+-----------+---------------+------+-----+---------+-------+
| taxid     | int(11)       | NO   |     | NULL    |       | 
| accno     | varchar(12)   | NO   | PRI | NULL    |       | 
| orgname   | varchar(1000) | YES  |     | NULL    |       | 
| seqlength | int(11)       | YES  |     | NULL    |       | 
+-----------+---------------+------+-----+---------+-------+

genedetails
-------------
Parsed version of the GFF information (containing the gene start and end positions, strand information, accession numbers and description)
+-------------+---------------+------+-----+---------+-------+
| Field       | Type          | Null | Key | Default | Extra |
+-------------+---------------+------+-----+---------+-------+
| accno       | varchar(15)   | NO   |     | NULL    |       | 
| protaccno   | varchar(15)   | YES  | MUL | NULL    |       | 
| geneid      | int(11)       | NO   | PRI | NULL    |       | 
| locus       | varchar(15)   | YES  |     | NULL    |       | 
| synonym     | varchar(5)    | YES  |     | NULL    |       | 
| start       | int(11)       | YES  |     | NULL    |       | 
| end         | int(11)       | YES  |     | NULL    |       | 
| strand      | varchar(1)    | YES  |     | NULL    |       | 
| description | varchar(5000) | YES  |     | NULL    |       | 
+-------------+---------------+------+-----+---------+-------+

geneseqs
-----------
Table containing all the NT sequences corresponding to the GFF entries
+----------+-------------+------+-----+---------+-------+
| Field    | Type        | Null | Key | Default | Extra |
+----------+-------------+------+-----+---------+-------+
| geneid   | varchar(15) | NO   | PRI | NULL    |       | 
| sequence | text        | YES  |     | NULL    |       | 
+----------+-------------+------+-----+---------+-------+

aaseqs
----------
Table containing all the AA sequences corresponding to the GFF entries
+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| protaccno | varchar(15) | NO   | PRI | NULL    |       | 
| sequence  | text        | YES  |     | NULL    |       | 
+-----------+-------------+------+-----+---------+-------+

EUKARYOTES

taxid_orgname_Euk
-------------------
Table used to link the list of available organisms to their taxonomy ID. To make the table structure of Eukaryotes match with the Prokaryotes, internally, we
created our own taxonomy IDs and nomenclature for the dataset. The taxid's are represented by combining the first letters of the genus and species name of an
organism. For eg: for Homo sapiens, taxonomy ID is HS.
+---------+--------------+------+-----+---------+-------+
| Field   | Type         | Null | Key | Default | Extra |
+---------+--------------+------+-----+---------+-------+
| taxid   | varchar(2)   | NO   | PRI | NULL    |       | 
| orgname | varchar(100) | NO   |     | NULL    |       | 
+---------+--------------+------+-----+---------+-------+

taxid_accno_Euk
------------------
This table is used to link the taxonomy ID to the representative chromosomes of the particular organism. For eg: for Homo sapiens, the accession numbers are as 
follows: HS1, HS2, HS3, ...., HS22, HSX, HSY.
+-----------+--------------+------+-----+---------+-------+
| Field     | Type         | Null | Key | Default | Extra |
+-----------+--------------+------+-----+---------+-------+
| taxid     | varchar(2)   | NO   |     | NULL    |       | 
| accno     | varchar(4)   | NO   |     | NULL    |       | 
| orgname   | varchar(100) | YES  |     | NULL    |       | 
| seqlength | int(11)      | YES  |     | NULL    |       | 
+-----------+--------------+------+-----+---------+-------+

genedetails_Euk
-----------------
This table is the parsed version of the GTF file corresponding to a particular organism (containing the gene start and end positions, strand information, gene ID, 
transcript ID, protein ID and description)
+------------------+-------------+------+-----+---------+-------+
| Field            | Type        | Null | Key | Default | Extra |
+------------------+-------------+------+-----+---------+-------+
| accno            | varchar(4)  | NO   |     | NULL    |       | 
| protaccno        | varchar(35) | YES  |     | NULL    |       | 
| gene_id          | varchar(35) | YES  |     | NULL    |       | 
| gene_start       | int(11)     | YES  |     | NULL    |       | 
| gene_end         | int(11)     | YES  |     | NULL    |       | 
| transcript_id    | varchar(35) | YES  |     | NULL    |       | 
| transcript_start | int(11)     | YES  |     | NULL    |       | 
| transcript_end   | int(11)     | YES  |     | NULL    |       | 
| strand           | varchar(1)  | YES  |     | NULL    |       | 
| description      | varchar(25) | YES  |     | NULL    |       | 
+------------------+-------------+------+-----+---------+-------+

aaseqs_Euk
-------------
Table containing all the AA sequences corresponding to the GTF entries.
+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| protaccno | varchar(25) | NO   | PRI | NULL    |       | 
| sequence  | text        | YES  |     | NULL    |       | 
+-----------+-------------+------+-----+---------+-------+
