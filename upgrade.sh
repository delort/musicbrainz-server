#!/bin/bash

set -o errexit
cd `dirname $0`

eval `./admin/ShowDBDefs`

echo `date` : Dumping RAWDATA
eval $(perl -Ilib -MString::ShellQuote -MDBDefs -MMusicBrainz::Server::DatabaseConnectionFactory -e '
    my $db = MusicBrainz::Server::DatabaseConnectionFactory->get("RAWDATA");
    my $rw = MusicBrainz::Server::DatabaseConnectionFactory->get("READWRITE");
    printf "export MB_RAWDATA_%s=%s\n", uc($_), shell_quote($db->$_),
        for qw( username password schema port database host );
    printf "export MB_READWRITE_%s=%s\n", uc($_), shell_quote($rw->$_),
        for qw( username password schema port database host );
')
pg_dump --format=p --schema=musicbrainz --host=$MB_RAWDATA_HOST --username=$MB_RAWDATA_USERNAME -v -a \
    $MB_RAWDATA_DATABASE  > rawdata.dump

echo `date` : Loading RAWDATA into READWRITE
./admin/psql READWRITE <./admin/sql/vertical/rawdata/CreateTables.sql
./admin/psql READWRITE < rawdata.dump

echo `date` : Fixing potential FK violations
./admin/psql READWRITE < ./admin/sql/updates/20110707-fk-constraints.sql

./admin/psql READWRITE <./admin/sql/vertical/rawdata/CreatePrimaryKeys.sql
./admin/psql READWRITE <./admin/sql/vertical/rawdata/CreateFunctions.sql
./admin/psql READWRITE <./admin/sql/vertical/rawdata/CreateIndexes.sql
./admin/psql READWRITE <./admin/sql/vertical/rawdata/CreateFKConstraints.sql
./admin/psql READWRITE <./admin/sql/updates/20110708-new-fks.sql
./admin/psql READWRITE <./admin/sql/vertical/rawdata/SetSequences.sql

echo `date` : RAWDATA is now part of the READWRITE database.
echo `date` : Please update your DBDefs and feel free to drop the RAWDATA database

echo `date` : Materializing edit.status onto edit_artist and edit_label
./admin/psql READWRITE < ./admin/sql/updates/20110707-materialize-status.sql

echo `date` : Done

# eof
