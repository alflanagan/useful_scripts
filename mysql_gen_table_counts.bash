#!/bin/bash
if [[ $# -lt 1 ]]; then
    echo
    echo $(basename $0) db_name
    echo "      Outputs a SQL script to get the record counts for tables in a MySQL db."
    echo
    exit 1
fi

DB_NAME=$1
TMP_FILE=$(mktemp)
TMP_FILE2=$(mktemp)

mysql -u root -p > $TMP_FILE <<HERE
SELECT 'USE ${DB_NAME}' AS '' UNION
SELECT concat('SELECT \'', table_name, '\' AS tname, COUNT(*) AS cnt FROM ',
              table_name, ' UNION') AS ''
  FROM information_schema.tables
 WHERE table_schema = '$DB_NAME';
HERE

head -n -1 ${TMP_FILE} > ${TMP_FILE2}
tail -n 1 ${TMP_FILE} | sed -e 's/ UNION/;/' >> ${TMP_FILE2}
rm -f ${TMP_FILE}
cat ${TMP_FILE2}
rm -f ${TMP_FILE2}
