SELECT dbVersion
FROM "version"
WHERE COALESCE('{{APP_VERSION}}',appVersion) = appVersion
ORDER BY time DESC
LIMIT 1