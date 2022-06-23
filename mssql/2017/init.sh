#!/bin/bash

echo =============== WAITING FOR MSSQL ==========================
#waiting for mssql to start
export STATUS=0
i=0
while [[ $STATUS -eq 0 ]] || [[ $i -lt 90 ]]; do
	sleep 1
	i=$((i+1))
	STATUS=$(grep 'SQL Server is now ready for client connections' /var/opt/mssql/log/errorlog | wc -l)
done

echo =============== MSSQL STARTED ==========================

if [ ! -z $MSSQL_USER ]; then
	echo "MSSQL_USER: $MSSQL_USER"	
else
	MSSQL_USER=tester
	echo "MSSQL_USER: $MSSQL_USER"
fi

if [ ! -z $MSSQL_PASSWORD ]; then
	echo "MSSQL_PASSWORD: $MSSQL_PASSWORD"	
else
	MSSQL_PASSWORD=My@Super@Secret
	echo "MSSQL_PASSWORD: $MSSQL_PASSWORD"
fi

if [ ! -z $MSSQL_DB ]; then
	echo "MSSQL_DB: $MSSQL_DB"	
else
	MSSQL_DB=testdb
	echo "MSSQL_DB: $MSSQL_DB"
fi

echo =============== CREATING INIT DATA ==========================

cd /opt/mssql/

cat <<-EOSQL > init.sql
CREATE DATABASE $MSSQL_DB;
GO

USE $MSSQL_DB;
GO

CREATE LOGIN $MSSQL_USER WITH PASSWORD = '$MSSQL_PASSWORD';
GO

CREATE USER $MSSQL_USER FOR LOGIN $MSSQL_USER;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER [$MSSQL_USER];
GO

EOSQL

cat <<-EOSQL > init_memory.sql
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'min server memory', 2048;
GO
RECONFIGURE;
GO
sp_configure 'max server memory', 4096;
GO
RECONFIGURE;
GO
EOSQL

cd /opt/mssql-tools/bin/
./sqlcmd -S localhost -U sa -P $SA_PASSWORD -t 30 -i"/opt/mssql/init.sql" -o"/opt/mssql/initout.log"
./sqlcmd -S localhost -U sa -P $SA_PASSWORD -t 30 -i"/opt/mssql/init_memory.sql" -o"/opt/mssql/initout2.log"

echo =============== INIT DATA CREATED ==========================


echo =============== MSSQL SERVER SUCCESSFULLY STARTED ==========================

#trap
while [ "$END" == '' ]; do
			sleep 1
			trap "END=1" INT TERM
done
