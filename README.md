## MediaWiki backuprestore.sh

Add this to the end of LocalSettings.php:
   

    if (file_exists("$IP/maintenance/backuprestore.sh") && !file_exists("backups/backup.sql")) {
        $fp = fopen("backup.lck", 'w+');
        if (flock($fp, LOCK_EX)) {
            fwrite($fp, 'a');
            $wgReadOnly = 'Performing backup, write access will be restored shortly';
            $retval = 0;
            $last_line = system("bash '$IP/maintenance/backuprestore.sh' backup", $retval);
            flock($fp, LOCK_UN);
        }
    }

