#!/bin/bash

mkdir -m 0700 -p backups
backupfile=backups/backup

wgDBOldPrefix=""
wgDBserver="localhost"
wgDBname="mediawiki"
wgDBuser="mediawiki"
wgDBpassword=""
wgDBprefix=""

. <(grep '$wgDB' LocalSettings.php | sed -e 's, = ,=,' -e 's,;$,,' -e 's,^\$,,')

# Detect prefix in backup
if [ -e "$backupfile".sql ] ; then
    wgDBOldPrefix=$(grep -E "DROP TABLE .*uw_campaign" "$backupfile".sql  | head -n1 | cut -d\` -f2)
    case $wgDBOldPrefix in
    uw_campaign)
        wgDBOldPrefix=""
        ;;
    *uw_campaign)
        wgDBOldPrefix=${wgDBOldPrefix%uw_campaign}
        ;;
    esac
    #[ -z "$wgDBprefix" ] || wgDBprefix=${wgDBprefix}
fi

case $1 in
backup)
    mysqldump -h "$wgDBserver" -u "$wgDBuser" --password="$wgDBpassword" \
       --default-character-set=binary "$wgDBname" | \
    sed -e 's/DROP TABLE IF EXISTS `'"$wgDBprefix"'/DROP TABLE IF EXISTS `/' \
        -e 's/CREATE TABLE `'"$wgDBprefix"'/CREATE TABLE `/' \
        -e 's/INSERT INTO `'"$wgDBprefix"'/INSERT INTO `/' \
        -e 's/LOCK TABLES `'"$wgDBprefix"'/LOCK TABLES `/' \
        -e 's/ALTER TABLE `'"$wgDBprefix"'/ALTER TABLE `/' \
    > "$backupfile".sql
    ;;

restore)
    sed -e 's/DROP TABLE IF EXISTS `'"$wgDBOldPrefix"'/DROP TABLE IF EXISTS `/' \
        -e 's/CREATE TABLE `'"$wgDBOldPrefix"'/CREATE TABLE `/' \
        -e 's/INSERT INTO `'"$wgDBOldPrefix"'/INSERT INTO `/' \
        -e 's/LOCK TABLES `'"$wgDBOldPrefix"'/LOCK TABLES `/' \
        -e 's/ALTER TABLE `'"$wgDBOldPrefix"'/ALTER TABLE `/' "$backupfile".sql | \
    sed -e 's/DROP TABLE IF EXISTS `/DROP TABLE IF EXISTS `'"$wgDBprefix"'/' \
        -e 's/CREATE TABLE `/CREATE TABLE `'"$wgDBprefix"'/' \
        -e 's/INSERT INTO `/INSERT INTO `'"$wgDBprefix"'/' \
        -e 's/LOCK TABLES `/LOCK TABLES `'"$wgDBprefix"'/' \
        -e 's/ALTER TABLE `/ALTER TABLE `'"$wgDBprefix"'/' | \
    mysql -h "$wgDBserver" -u "$wgDBuser" --password="$wgDBpassword" "$wgDBname"
    ;;

reset)
    mysql -h "$wgDBserver" -u "$wgDBuser" --password="$wgDBpassword" "$wgDBname" <<'EOF'
SET FOREIGN_KEY_CHECKS = 0;
SET GROUP_CONCAT_MAX_LEN=32768;
SET @tables = NULL;
SELECT GROUP_CONCAT('`', table_name, '`') INTO @tables
  FROM information_schema.tables
  WHERE table_schema = (SELECT DATABASE());
SELECT IFNULL(@tables, 'dummy') INTO @tables;

SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables);
PREPARE stmt FROM @tables;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET FOREIGN_KEY_CHECKS = 1;
EOF
    ;;

esac

