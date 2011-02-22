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

package DB;

use strict;
use warnings;

{

  my $db;
  
#------------------------------------------------------------------------

=item PRIVATE void _connect();

Opens a connection to the database.

=cut
#------------------------------------------------------------------------
  sub _connect {

    my $class = shift;
    
    # singleton
    $db and return;
    
    my $params = {db => '_____DB_DATABASE_____', user => '_____DB_USER_____', password => '_____DB_PASSWORD_____', host => '_____DB_HOST_____' };
    
    my $string = "dbi:mysql:dbname=$params->{db}";
    
    if ( my $host = $params->{host} ) {
      $string .= ";host=$host";
    }
    
    # create an anonymous hash for instance variables
    $db = DBI->connect($string, @$params{ qw( user password ) },
                       { RaiseError => 1, PrintError => 0}
                      );
  }

#------------------------------------------------------------------------

=item PRIVATE void _diconnect();

Closes connection to the database if it exists.

=cut
#------------------------------------------------------------------------
  sub _disconnect { 
    
    my $class = shift;
    ref $db and $db->disconnect; 
    $db = undef;
  }

#------------------------------------------------------------------------

=item public static [tuple] exec(string query, [SCALAR] parameters);

Executes an SQL query with the provided parameters. This method
returns the results of the queries as a reference to an array of
arrays. The order of elements in each array corresponds to the order
of fields in the SELECT statement. If the query results in an error, a
QueryError exception will be raised.

=cut
#------------------------------------------------------------------------
  sub exec {
    
    my ($class, $sql, $params) = @_;
    
    my $statement = $db->prepare($sql);
    
    eval { $statement->execute(@$params) };
    
    if ( $@ ) {

#      SysMicro::X->lookup_pg_error($statement->state)->throw
#        (error => $@,
#         query => $sql,
#         params => $params);
    }  
    
    return $statement->fetchall_arrayref();
  }

#------------------------------------------------------------------------

=item public static {tuple} exec_hashref(string query, [SCALAR] parameters);

Executes an SQL query with the provided parameters. This method
returns the results of the queries as a reference to an array of
arrays. The order of elements in each array corresponds to the order
of fields in the SELECT statement. If the query results in an error, a
QueryError exception will be raised.

=cut
#------------------------------------------------------------------------
  sub exec_hashref {
    
    my ($class, $sql, $params) = @_;
    
    my $statement = $db->prepare($sql);
    
    eval { $statement->execute(@$params) };
    
    if ( $@ ) {

#      SysMicro::X->lookup_pg_error($statement->state)->throw
#        (error => $statement->errstr,
#         query => $sql,
#         params => $params);
    }  

    my $res = [];
    while ( my $row = $statement->fetchrow_hashref() ) {
      push @$res, $row;
    }

    return $res;
  }

#------------------------------------------------------------------------

=item public int do(string query, [SCALAR] parameters);

Executes an SQL query stored in the given string and returns the
number of rows modified.  If the query results in an error, a
QueryError exception will be raised.

For example, the query:

    INSERT INTO refsTable VALUES (beml,acop)

should return a value of 1.

This should not be used with SELECT queries because the resulting rows
selected form that table(s) will not be accessible to the caller.

=cut
#------------------------------------------------------------------------
  sub do {
      
    my ($class, $sql, $params) = @_;
      
    my $result;
    eval { $result = $db->do($sql, {}, @$params) };
      
    if ( $@ ) {
      
 #     SysMicro::X->lookup_pg_error($db->state)->throw(error => $@,
 #                                                      query => $sql,
 #                                                      params => $params);
    }
    
    # and return the array of data
    return $result;
  }
  
#------------------------------------------------------------------------

=item public static DB state();

This method is passed on to the DBI handle.

=cut
#------------------------------------------------------------------------
  sub state { $db->state; }
    
#------------------------------------------------------------------------

=item public static DB err();

This method is passed on to the DBI handle.

=cut
#------------------------------------------------------------------------
  sub err { $db->err; }
    
#------------------------------------------------------------------------

=item public static DB errstr();

This method is passed on to the DBI handle.

=cut
#------------------------------------------------------------------------
  sub errstr { $db->errstr; }

#------------------------------------------------------------------------

=item public static DB ping();

This method is passed on to the DBI handle.

=cut
#------------------------------------------------------------------------
  sub ping { $db->ping; }

#------------------------------------------------------------------------

=item public Bool inTransaction();

Returns true if the database is in a transaction, and false otherwise.

=cut
#
#------------------------------------------------------------------------
  sub inTransaction { return ( $db->{AutoCommit} ? 0 : 1); }

#------------------------------------------------------------------------

=item public Void begin_work();

Returns the autocommit value for the database handle

=cut
#
#------------------------------------------------------------------------
  sub begin_work { $db->begin_work; }

#------------------------------------------------------------------------

=item public Void commit();

Successfully end a transaction - commit queries and reset autocommit

=cut
#
#------------------------------------------------------------------------
  sub commit { $db->commit(); }

#------------------------------------------------------------------------

=item public Void rollback();

Successfully end a transaction - commit queries and reset autocommit

=cut
#
#------------------------------------------------------------------------
  sub rollback { $db->rollback(); }

  __PACKAGE__->_connect();
}

1;
__END__

