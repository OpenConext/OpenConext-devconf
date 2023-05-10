CREATE DATABASE IF NOT EXISTS webauthn;
CREATE DATABASE IF NOT EXISTS tiqr;
CREATE DATABASE IF NOT EXISTS gateway;

CREATE USER IF NOT EXISTS 'webauthn_user'@'%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON webauthn.* TO 'webauthn_user'@'%';

CREATE USER IF NOT EXISTS 'tiqr_user'@'%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON tiqr.* TO 'tiqr_user'@'%';

CREATE USER IF NOT EXISTS 'gateway_user'@'%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON gateway.* TO 'gateway_user'@'%';

