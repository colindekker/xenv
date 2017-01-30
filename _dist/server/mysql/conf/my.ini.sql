SET PASSWORD FOR 'root'@'localhost' = PASSWORD('Password123');
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;