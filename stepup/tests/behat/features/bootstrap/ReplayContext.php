<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
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
     * @Given a replay is performed
     */
    public function replay()
    {
        // Generate test databases
        echo "Preparing test schemas\n";
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 bin/console doctrine:schema:drop --em=middleware --env=smoketest --force');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 bin/console doctrine:schema:drop --em=gateway --env=smoketest --force');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 bin/console doctrine:schema:create --em=middleware --env=smoketest');
        FeatureContext::execCommand('docker exec -t stepup-middleware-1 bin/console doctrine:schema:create --em=gateway --env=smoketest');

        // Import the events.sql into middleware
        echo "Add events to test database\n";
        FeatureContext::execCommand("mysql -uroot -psecret middleware_test -h mariadb < ./fixtures/eventstream.sql");

        // Perform an event replay
        echo "Replaying event stream\n";
        FeatureContext::execCommand("docker exec -t stepup-middleware-1 bin/console middleware:event:replay --env=smoketest_event_replay --no-interaction -vvv");
    }
}
