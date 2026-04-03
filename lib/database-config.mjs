function requireEnv(name, fallback = '') {
  const value = String(process.env[name] || fallback).trim();
  return value;
}

export function resolvePrimaryDatabaseConfig() {
  return {
    vendor: 'oracle',
    oracleUser: requireEnv('ORACLE_USER'),
    oraclePassword: requireEnv('ORACLE_PASSWORD'),
    oracleConnectString: requireEnv('ORACLE_CONNECT_STRING')
  };
}

export function resolveCacheLoaderMetadataConfig() {
  return {
    vendor: 'oracle',
    oracleUser: requireEnv('CACHE_LOADER_METADATA_ORACLE_USER', requireEnv('ORACLE_USER')),
    oraclePassword: requireEnv(
      'CACHE_LOADER_METADATA_ORACLE_PASSWORD',
      requireEnv('ORACLE_PASSWORD')
    ),
    oracleConnectString: requireEnv(
      'CACHE_LOADER_METADATA_ORACLE_CONNECT_STRING',
      requireEnv('ORACLE_CONNECT_STRING')
    )
  };
}

export function describeDatabaseTarget(config) {
  return config.oracleConnectString || 'oracle-connect-string-missing';
}
