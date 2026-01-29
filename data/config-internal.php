<?php
return [
  'database' => [
    'host' => 'db',
    'port' => '',
    'charset' => NULL,
    'dbname' => 'db',
    'user' => 'db',
    'password' => 'db',
    'platform' => 'Mysql'
  ],
  'smtpPassword' => NULL,
  'logger' => [
    'path' => 'data/logs/espo.log',
    'level' => 'WARNING',
    'rotation' => true,
    'maxFileNumber' => 30,
    'printTrace' => false,
    'databaseHandler' => false,
    'sql' => false,
    'sqlFailed' => false
  ],
  'restrictedMode' => false,
  'cleanupAppLog' => true,
  'cleanupAppLogPeriod' => '30 days',
  'webSocketMessager' => 'ZeroMQ',
  'clientSecurityHeadersDisabled' => false,
  'clientCspDisabled' => false,
  'clientCspScriptSourceList' => [
    0 => 'https://maps.googleapis.com'
  ],
  'adminUpgradeDisabled' => false,
  'isInstalled' => true,
  'microtimeInternal' => 1769704970.894526,
  'cryptKey' => 'fe422b9b94227c692a95e1f8058822e4',
  'hashSecretKey' => 'd8ddc40c6be9c1ddb6bf9beb71e129dd',
  'defaultPermissions' => [
    'user' => 1000,
    'group' => 1000
  ],
  'actualDatabaseType' => 'mariadb',
  'actualDatabaseVersion' => '10.11.14',
  'instanceId' => '8792ed57-9672-4e6d-912d-56dc04ab7f43'
];
