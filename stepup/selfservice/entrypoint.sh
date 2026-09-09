#!/usr/bin/env sh

set -eu

OVERRIDE_FILE="/config/selfservice/parameters.override.yaml"

if [ -f "$OVERRIDE_FILE" ]; then
  # Keep the image's base config intact and override only the local keys we need.
  php <<'PHP'
<?php

require '/var/www/html/vendor/autoload.php';

use Symfony\Component\Yaml\Yaml;

$parametersPath = '/var/www/html/config/openconext/parameters.yaml';
$overridePath = '/config/selfservice/parameters.override.yaml';

$parameters = Yaml::parseFile($parametersPath);
$override = Yaml::parseFile($overridePath);

foreach ($override as $section => $values) {
    if (!is_array($values)) {
        $parameters[$section] = $values;
        continue;
    }

    $currentValues = $parameters[$section] ?? [];
    if (!is_array($currentValues)) {
        $currentValues = [];
    }

    $parameters[$section] = array_replace_recursive($currentValues, $values);
}

file_put_contents(
    $parametersPath,
    Yaml::dump($parameters, 99, 4, Yaml::DUMP_MULTI_LINE_LITERAL_BLOCK)
);
PHP
fi

exec /entrypoint.sh "$@"
