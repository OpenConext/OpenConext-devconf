<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Gherkin\Node\TableNode;
use Behat\MinkExtension\Context\MinkContext;

class ReplayContext implements Context
{
    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
    }

    /**
     * @Given a replay of :arg is performed
     */
    public function replay($name)
    {
        // Generate test databases
        echo "Preparing test schemas\n";
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 php bin/console doctrine:schema:drop --em=middleware --env=smoketest --force');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 php bin/console doctrine:schema:drop --em=gateway --env=smoketest --force');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 php bin/console doctrine:schema:create --em=middleware --env=smoketest');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 php bin/console doctrine:schema:create --em=gateway --env=smoketest');

        // Import the events.sql into middleware
        echo "Add events to test database\n";
        FeatureContext::execCommand("mysql -uroot -psecret middleware_test -h mariadb < ./fixtures/".$name.".sql");

        // Perform an event replay
        echo "Replaying event stream\n";
        FeatureContext::execCommand("docker exec -t stepup-middleware-1 php bin/console middleware:event:replay --env=smoketest_event_replay --no-interaction -vvv");
    }


    /**
     * @Given the database should not contain
     * @param TableNode $table
     */
    public function tempDataBaseDoesNotContains(TableNode $table)
    {
        FeatureContext::execCommand("mysqldump -h mariadb -u root -psecret --single-transaction --databases middleware_test gateway_test > temp.sql");
        $dataset = file_get_contents('temp.sql');

        $hash = $table->getHash();
        foreach ($hash as $row) {
            if (str_contains($dataset, $row['value'])) {
                throw new RuntimeException(sprintf("Data %s with value %s is still in the data set.", $row['name'], $row['value']));
            }
        }
    }
}
