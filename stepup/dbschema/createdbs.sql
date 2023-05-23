CREATE DATABASE IF NOT EXISTS webauthn;
CREATE DATABASE IF NOT EXISTS tiqr;
CREATE DATABASE IF NOT EXISTS gateway;
CREATE DATABASE IF NOT EXISTS middleware;

CREATE USER IF NOT EXISTS 'webauthn_user'@'%' IDENTIFIED BY 'webauthn_secret';
GRANT ALL PRIVILEGES ON webauthn.* TO 'webauthn_user'@'%';

CREATE USER IF NOT EXISTS 'tiqr_user'@'%' IDENTIFIED BY 'tiqr_secret';
GRANT ALL PRIVILEGES ON tiqr.* TO 'tiqr_user'@'%';

CREATE USER IF NOT EXISTS 'gateway_user'@'%' IDENTIFIED BY 'gateway_secret';
GRANT SELECT ON gateway.* TO 'gateway_user'@'%';

CREATE USER IF NOT EXISTS 'middleware_user'@'%' IDENTIFIED BY 'middleware_secret';
GRANT SELECT,INSERT,DELETE,UPDATE ON middleware.* TO 'middleware_user'@'%';

CREATE USER IF NOT EXISTS 'mw_gateway_user'@'%' IDENTIFIED BY 'mw_gateway_secret';
GRANT SELECT,INSERT,DELETE,UPDATE ON gateway.* TO 'mw_gateway_user'@'%';

CREATE USER IF NOT EXISTS 'mw_deploy_user'@'%' IDENTIFIED BY 'mw_deploy_secret';
GRANT ALL PRIVILEGES ON gateway.* TO 'mw_deploy_user'@'%';
GRANT ALL PRIVILEGES ON middleware.* TO 'mw_deploy_user'@'%';

CREATE USER IF NOT EXISTS 'gw_deploy_user'@'%' IDENTIFIED BY 'gw_deploy_secret';
GRANT ALL PRIVILEGES ON gateway.* TO 'gw_deploy_user'@'%';
