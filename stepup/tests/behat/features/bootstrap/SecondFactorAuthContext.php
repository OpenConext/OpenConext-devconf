<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Mink\Exception\ElementNotFoundException;
use Behat\MinkExtension\Context\MinkContext;

class SecondFactorAuthContext implements Context
{
    const SSO_IDP = 'https://gateway.dev.openconext.local/authentication/metadata';
    const SFO_IDP = 'https://gateway.dev.openconext.local/second-factor-only/metadata';
    const SSO_SP = 'default-sp';
    const SFO_SP = 'second-sp';
    const TEST_NAMEID = 'urn:collab:person:institution-a.example.com:jane-a1';
    const TEST_NAMEID_ADFS = 'urn:collab:person:dev.openconext.local:admin';

    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @var string
     */
    private $spTestUrl;

    /**
     * @var string
     */
    private $activeIdp;

    /**
     * @var string
     */
    private $activeSp;

    /**
     * @var int
     */
    private $requiredLoa;

    /**
     * @var string
     */
    private $storedAuthnRequest;
    /**
     * @var string
     */
    private $storedChallengeCode;

    /**
     * Initializes context.
     */
    public function __construct($spTestUrl)
    {
        $this->spTestUrl = $spTestUrl;
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
    }

    /**
     * @Given a service provider configured for second-factor-only
     */
    public function configureServiceProviderForSecondFactorOnly()
    {
        $this->activeIdp = self::SFO_IDP;
        $this->activeSp = self::SFO_SP;
        $this->requiredLoa = 2;
    }

    /**
     * @Given a service provider configured for single-signon
     */
    public function configureServiceProviderForSingleSignOn()
    {
        $this->activeIdp = self::SSO_IDP;
        $this->activeSp = self::SSO_SP;
        $this->requiredLoa = 2;
    }

    /**
     * @When I visit the service provider
     */
    public function visitServiceProvider()
    {
        $this->minkContext->visit($this->spTestUrl);

        $this->minkContext->fillField('idp', $this->activeIdp);
        $this->minkContext->fillField('sp', $this->activeSp);
        $this->minkContext->fillField('loa', $this->requiredLoa);

        if ($this->activeIdp === self::SFO_IDP) {
            $this->minkContext->fillField('subject', self::TEST_NAMEID);
        }
        $this->minkContext->pressButton('Login');
        if ($this->activeIdp === self::SFO_IDP) {
            // Pass through the SFO endpoint in Gateway
            $this->minkContext->pressButton('Submit');
            $this->diePrintingContent();
        }
    }

    /**
     * @When I start an SFO authentication for :arg1
     */
    public function startASfoAuthenticationFor(string $userIdentifier)
    {
        $this->minkContext->visit($this->spTestUrl);
        $this->minkContext->fillField('idp', $this->activeIdp);
        $this->minkContext->fillField('sp', $this->activeSp);
        $this->minkContext->fillField('loa', $this->requiredLoa);
        $this->minkContext->fillField('subject', $userIdentifier);
        $this->minkContext->pressButton('Login');
    }

    /**
     * @When I visit the ADFS service provider
     */
    public function visitAdfsServiceProvider()
    {
        $nameId = self::TEST_NAMEID;
        if ($this->activeIdp === self::SFO_IDP) {
            $nameId = self::TEST_NAMEID_ADFS;
        }
        $this->logInSimulatingAdfsFor($nameId);
    }

    /**
     * @When I start an ADFS authentication for :arg1
     */
    public function logInSimulatingAdfsFor(string $userIdentifier)
    {
        $this->minkContext->visit($this->spTestUrl);
        $this->minkContext->fillField('idp', $this->activeIdp);
        $this->minkContext->selectOption('sp', $this->activeSp);
        $this->minkContext->fillField('loa', $this->requiredLoa);
        $this->minkContext->selectOption('ssobinding', 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST');
        $this->minkContext->checkOption('emulateadfs');

        $this->minkContext->fillField('subject', $userIdentifier);
        $this->minkContext->pressButton('Login');
        $this->minkContext->pressButton('Yes, continue');
    }

    private function fillField($session, $field, $value)
    {
        $field = $this->fixStepArgument($field);
        $value = $this->fixStepArgument($value);
        $this->minkContext->getSession($session)->getPage()->fillField($field, $value);
    }
    private function fixStepArgument($argument)
    {
        return str_replace('\\"', '"', $argument);
    }

    /**
     * @Given the service provider requires no second factor
     */
    public function setImplicitLoaOnServiceProvider()
    {
        $this->requiredLoa = 1;
    }

    /**
     * @When I verify the :arg1 second factor
     */
    public function verifySpecifiedSecondFactor($tokenType, $smsChallenge = null)
    {
        switch ($tokenType){
            case "sms":
                // Pass through acs
                $this->minkContext->pressButton('Submit');
                $this->authenticateUserSmsInGateway($smsChallenge);
                break;
            case "yubikey":
                $this->authenticateUserYubikeyInGateway();
                break;
            case "demo-gssp":
                $this->authenticateUserInDummyGsspApplication();
                break;
            default:
                throw new Exception(
                    sprintf(
                        'Second factor type of "%s" is not yet supported in the tests.',
                        $tokenType
                    )
                );
        }
    }

    /**
     * @When I verify the Yubikey second factor
     */
    public function verifyYuikeySecondFactor()
    {
        $this->authenticateUserYubikeyInGateway();
    }

    public function verifyGsspSecondFactor()
    {
        $this->authenticateUserGsspInGateway();
    }

    /**
     * @When I cancel the :arg1 second factor authentication
     */
    public function cancelSecondFactorAuthentication($tokenType)
    {
        switch ($tokenType){
            case "yubikey":
                $this->cancelYubikeySsoAuthentication();
                break;
            case "demo-gssp":
                $this->cancelAuthenticationInDummyGsspApplication();
                break;
            default:
                throw new Exception(
                    sprintf(
                        'Second factor type of "%s" is not yet supported in the tests.',
                        $tokenType
                    )
                );
                break;
        }
    }

    /**
     * @Then second factor authentication is not initiated
     */
    public function secondFactorAuthenticationIsNotInitiated()
    {
        $this->passTroughGatewaySsoAssertionConsumerService();
    }

    public function selectDummySecondFactorOnTokenSelectionScreen()
    {
        $this->minkContext->pressButton('gateway_choose_second_factor_choose_dummy');
    }

    public function selectYubikeySecondFactorOnTokenSelectionScreen()
    {
        $this->minkContext->pressButton('gateway_choose_second_factor_choose_yubikey');
    }

    public function authenticateUserInDummyGsspApplication()
    {
        $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/authentication');

        // Trigger the dummy authentication action.
        $this->minkContext->pressButton('Authenticate user');

        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
        // And continue back to the SP via Gateway
        $this->minkContext->pressButton('Submit');
    }

    public function authenticateUserYubikeyInGateway()
    {
        try {
            $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/verify-second-factor/sso/yubikey');
        } catch (Exception $e) {
            $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/verify-second-factor/sfo/yubikey');
        }
        // Give an OTP
        $this->minkContext->fillField('gateway_verify_yubikey_otp_otp', 'ccccccdhgrbtucnfhrhltvfkchlnnrndcbnfnnljjdgf');
        // Simulate the enter press the yubikey otp generator
        $form = $this->minkContext->getSession()->getPage()->find('css', '[id="gateway_verify_yubikey_otp_otp"]');
        if (!$form) {
            throw new ElementNotFoundException('Yubikey OTP Submit form could not be found on the page');
        }
        $this->minkContext->pressButton('gateway_verify_yubikey_otp_submit');
        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    public function authenticateUserGsspInGateway()
    {
        $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/authentication');
        $this->minkContext->pressButton('button_authenticate');
        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
        $this->minkContext->pressButton('Submit');
    }

    public function authenticateUserSmsInGateway(string $challenge)
    {
        $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/verify-second-factor/sms/verify-challenge');
        // Fill the challenge
        $this->minkContext->fillField('gateway_verify_sms_challenge_challenge', $challenge);
        // Submit the form
        $this->minkContext->pressButton('Verify code');
        $this->minkContext->assertResponseNotContains('stepup.verify_possession_of_phone_command.challenge.may_not_be_empty');
    }

    public function cancelAuthenticationInDummyGsspApplication()
    {
        $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/authentication');

        // Cancel the dummy authentication action.
        $this->minkContext->pressButton('Return authentication failed');

        // Pass through the gssp
        $this->minkContext->pressButton('Submit');
        // Pass through the Gateway
        $this->minkContext->pressButton('Submit');
    }

    public function cancelYubikeySsoAuthentication()
    {
        switch ($this->activeSp) {
            case 'second-sp':
                $this->minkContext->assertPageAddress('/verify-second-factor/sfo/yubikey');
                break;
            case 'default-sp':
                $this->minkContext->assertPageAddress('/verify-second-factor/sso/yubikey');
                break;
            default:
                throw new Exception($this->activeSp . ' is not supported for yubikey cancellation');
        }
        // Cancel the yubikey authentication action.
        $this->minkContext->pressButton('Cancel');
        // Pass through the 'return to sp' redirection page.
        $this->minkContext->pressButton('Submit');
    }

    public function passTroughGatewaySsoAssertionConsumerService()
    {
        $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/authentication/consume-assertion');

        $this->minkContext->pressButton('Submit');
    }

    public function passTroughGatewayProxyAssertionConsumerService()
    {
        $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/gssp/dummy/consume-assertion');

        $this->minkContext->pressButton('Submit');
    }

    /**
     * @When I authenticate with the identity provider
     */
    public function authenticateWithIdentityProvider()
    {
        $this->minkContext->assertPageAddress('https://ssp.dev.openconext.local/simplesaml/module.php/core/loginuserpass');

        $this->minkContext->fillField('username', 'user-a1');
        $this->minkContext->fillField('password', 'user-a1');

        $this->minkContext->pressButton('Login');
        $this->minkContext->pressButton('Yes, continue');

    }

    /**
     * @When I authenticate as :arg1 with the identity provider
     */
    public function authenticateWithIdentityProviderFor($userName)
    {
        $this->minkContext->assertPageAddress('https://ssp.dev.openconext.local/simplesaml/module.php/core/loginuserpass');

        $this->minkContext->fillField('username', $userName);
        $this->minkContext->fillField('password', $userName);

        $this->minkContext->pressButton('Login');
        $this->minkContext->pressButton('Yes, continue');

    }

    public function authenticateWithIdentityProviderForWithStepup($userName)
    {
        $this->minkContext->assertPageAddress('https://ssp.dev.openconext.local/simplesaml/module.php/core/loginuserpass');

        $this->minkContext->fillField('username', $userName);
        $this->minkContext->fillField('password', $userName);

        $this->minkContext->pressButton('Login');
        $this->minkContext->pressButton('Yes, continue');
    }

    /**
     * @Then I am logged on the service provider
     */
    public function assertLoggedInOnServiceProvider()
    {
        $this->minkContext->assertPageAddress('https://ssp.dev.openconext.local/simplesaml/sp.php');

        $this->minkContext->assertPageContainsText('You are logged in to SP');
    }

    /**
     * @Then I see an error at the service provider
     */
    public function assertErrorAtServiceProvider()
    {
        switch ($this->activeSp) {
            case 'second-sp':
                $this->minkContext->assertPageAddress('/simplesaml/module.php/debugsp/acs/second-sp');
                break;
            case 'default-sp':
                $this->minkContext->assertPageAddress('/simplesaml/module.php/saml/sp/saml2-acs.php/default-sp');
                break;
            default:
                throw new Exception($this->activeSp . ' is not supported');
        }

        $this->minkContext->assertPageContainsText(
            sprintf('Unhandled exception')
        );

        $this->minkContext->assertPageNotContainsText(
            sprintf('You are logged in to SP')
        );
    }

    /**
     * @Then I see an ADFS error at the service provider
     */
    public function assertAdfsErrorAtServiceProvider()
    {
        switch ($this->activeSp) {
            case 'second-sp':
                $this->minkContext->assertPageAddress('/simplesaml/module.php/debugsp/acs/second-sp');
                break;
            case 'default-sp':
                $this->minkContext->assertPageAddress('/simplesaml/module.php/debugsp/acs/default-sp');
                break;
            default:
                throw new Exception($this->activeSp . ' is not supported');
        }

        $this->minkContext->assertPageContainsText(
            sprintf('Unhandled exception')
        );

        $currentUrl = $this->minkContext->getSession()->getCurrentUrl();
        // With behat we can not verify if the Context and AuthMethod are present in the POST request data, but we can
        // check if Gateway added back the original query string
        $expectedAdfsParams = '?SAMLRequest=request_that_must_be_kept&Context=context_value_that_must_be_kept';
        // The original parameters sent by the ADFS client should still be on the Url
        if (strpos($currentUrl, $expectedAdfsParams) === false) {
            throw new Exception(
                sprintf(
                    'The original Adfs parameters are not on the error page (expected: "%s")',
                    $expectedAdfsParams
                )
            );
        }

        $this->minkContext->assertPageNotContainsText(
            sprintf('You are logged in to SP')
        );
    }

    /**
     * @When I prepare an SFO authentication as :arg1
     */
    public function prepareSfoAuthentication($nameId)
    {
        $this->minkContext->getSession('second')->visit($this->spTestUrl);

        $this->fillField('second', 'idp', $this->activeIdp);
        $this->fillField('second','sp', $this->activeSp);
        $this->fillField('second','loa', $this->requiredLoa);
        $this->fillField('second', 'subject', $nameId);
    }

    /**
     * @Given I start and intercept the SFO authentication
     */
    public function iStartASMSSFOAuthentication()
    {
        // To intercept the AuthNRequest, instruct the 'browser' not to auto-follow redirects
        $client = $this->minkContext->getSession('second')->getDriver()->getClient();
        $client->followRedirects(false);
        $this->minkContext->getSession('second')->getPage()->pressButton('Login');
        // Jump from SSP SP to Gateway (we are interested in that AR)
        $client->followRedirect();
        // Catch the Url containing he AuthNRequest, removing the trailing slash
        $this->storedAuthnRequest = $this->minkContext->getSession('second')->getCurrentUrl();
        // And back to normal
        $client->followRedirects(true);
    }

    /**
     * @Given I start the stored SFO session in the victims session remembering the challenge for :arg1
     */
    public function victimizeTheStoredSFORequest($phoneNumber)
    {
        if ($this->storedAuthnRequest === null) {
            throw new RuntimeException('There is no stored authentication request. First run step definition: "I start and intercept a SMS SFO authentication"');
        }
        $this->minkContext->visit($this->storedAuthnRequest);
        $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/verify-second-factor/sms/verify-challenge?authenticationMode=sfo');
        $this->storedChallengeCode[$phoneNumber] = $this->fetchSmsChallengeFromCookie($phoneNumber);
    }

    /**
     * @Given I use the stored SMS verification code for :arg1
     */
    public function iUseTheStoredVerificationCode($phoneNumber)
    {
        if (!isset($this->storedChallengeCode[$phoneNumber])) {
            throw new RuntimeException('There is no stored SMS challenge available for this phone number.');
        }
        $this->authenticateUserSmsInGateway($this->storedChallengeCode[$phoneNumber]);
    }

    private function fetchSmsChallengeFromCookie($phoneNumber): string
    {
        $cookies = $this->minkContext
            ->getSession()
            ->getDriver()
            ->getClient()
            ->getCookieJar()
            ->all();
        $expectedCookieName = sprintf("%s%s", 'smoketest-sms-service-', $phoneNumber);
        $bodyPattern = '/^Your.SMS.code:.([A-Z-0-9]+)$/';
        foreach ($cookies as $cookie) {
            if ($cookie->getName() === $expectedCookieName) {
                $bodyMatches = [];
                preg_match($bodyPattern, $cookie->getValue(), $bodyMatches);
                return array_pop($bodyMatches);
            }
        }
        throw new RuntimeException('SMS verification code was not found in smoketest cookie');
    }

    /**
     * @Then I start an SMS SSO session for :arg1 with verification code for :arg2
     */
    public function iStartAnSmsSSOSessionFor($userName, $phoneNumber)
    {
        $this->configureServiceProviderForSingleSignOn();
        $this->visitServiceProvider();
        // Pass through Gateway (already authenticated)
        $this->minkContext->pressButton('Submit');
        // Choose SMS token on WAYG
        $this->minkContext->pressButton('gateway_choose_second_factor[choose_sms]');
    }

    /**
     * @Then /^The verification code is invalid$/
     */
    public function theVerificationCodeIsInvalid()
    {
        $this->minkContext->assertResponseContains('This code is not correct. Please try again or request a new code.');
    }

    private function diePrintingContent()
    {
        echo $this->minkContext->getSession()->getCurrentUrl();
        echo $this->minkContext->getSession()->getPage()->getContent();
        die;
    }
}
