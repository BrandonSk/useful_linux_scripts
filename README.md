# useful_linux_scripts
Repository of scripts which I use to perform various tasks around home network.

#### zip_and_erase_backups.sh
Script to zip files in given folder, which are older than defined value of days:
   - files are moved into the archive
   - existing ZIP files are excluded
   - Zip file is stored in the same directory as original files.
I use this script to pack Mikrotik backups and configurations created via automatic backup and stored on FTP, but it can be used just for about anything.


#### synology_update_certificates.sh
Script to grab and update certificate used for Synology services.
Certificate is a wildcard certificate from Let'sEncrypt, which is renewed at the docker server.
Due to security, the variable with the user allowed to login and download certificates has been modified and must be updated.
Also check login rules and command restrictions for particular user at docker server sshd configuration.

