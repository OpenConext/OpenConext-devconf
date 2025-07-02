<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;

class SelfServiceContext implements Context
{
    /**
     * @var \Behat\MinkExtension\Context\MinkContext
     */
    private $minkContext;

    /**
     * @var SecondFactorAuthContext
     */
    private $authContext;

    /**
     * @var string
     */
    private $selfServiceUrl;

    /**
     * @var string
     */
    private $mailCatcherUrl;

    /**
     * @var string The activation code used to vet the second factor in RA (used in RaContext)
     */
    private $activationCode;

    /**
     * @var string The UUID that identifies the verified second factor (used in RaContext)
     */
    private $verifiedSecondFactorId;

    /**
     * Initializes context.
     */
    public function __construct($selfServiceUrl, $mailCatcherUrl)
    {
        $this->selfServiceUrl = $selfServiceUrl;
        $this->mailCatcherUrl = $mailCatcherUrl;
    }

    /**
     * @BeforeScenario
     */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
        $environment = $scope->getEnvironment();

        $this->minkContext = $environment->getContext(MinkContext::class);
        $this->authContext = $environment->getContext(SecondFactorAuthContext::class);
    }

    /**
     * @Given I am logged in into the selfservice portal
     */
    public function loginIntoSelfService()
    {
        $this->minkContext->visit($this->selfServiceUrl);

        $this->authContext->authenticateWithIdentityProvider();
        $this->authContext->passTroughGatewaySsoAssertionConsumerService();

        $this->minkContext->assertPageContainsText('Registration Portal');
    }

    /**
     * @Given I log out of the selfservice portal
     */
    public function logoutOfSelfService()
    {
        $this->minkContext->visit($this->selfServiceUrl);

        $this->minkContext->pressButton('Sign out');

        $expectBaseUrl = 'https://www.surf.nl/';
        if (substr($this->minkContext->getSession()->getCurrentUrl(), 0, strlen($expectBaseUrl)) !== $expectBaseUrl) {
            throw new Exception("after logout we should be redirected to the surf domain");
        }
    }

    /**
     * @Given /^I am logged in into the selfservice portal as "([^"]*)"$/
     */
    public function iAmLoggedInIntoTheSelfServicePortalAs($userName)
    {
        // We visit the Self Service location url
        $this->minkContext->visit($this->selfServiceUrl);
        $this->authContext->authenticateWithIdentityProviderFor($userName);
        $this->authContext->passTroughGatewaySsoAssertionConsumerService();

        $this->iSwitchLocaleTo('English');
        $this->minkContext->assertPageContainsText('Registration Portal');
    }


    /**
     * @Given /^I log in again into selfservice$/
     */
    public function loginAgainIntoSelfService()
    {
        // We visit the Self Service location url
        $this->minkContext->visit($this->selfServiceUrl);
        $this->minkContext->pressButton('Sign out');

        $this->minkContext->visit($this->selfServiceUrl);
        $this->minkContext->pressButton('Yes, continue');
        // Pass through Gateway (already authenticated)
        $this->minkContext->pressButton('Submit');

        $this->iSwitchLocaleTo('English');
        $this->minkContext->assertPageContainsText('Registration Portal');
    }


    /**
     * @Given /^I log into the selfservice portal as "([^"]*)" with activation preference "([^"]*)"$/
     */
    public function ilogIntoTheSelfServicePortalAsWithPreference($userName, $preference)
    {
        // We visit the Self Service location url
        $this->minkContext->visit($this->selfServiceUrl.'?activate='.$preference);
        $this->authContext->authenticateWithIdentityProviderFor($userName);
        $this->authContext->passTroughGatewaySsoAssertionConsumerService();
        $this->iSwitchLocaleTo('English');
        $this->minkContext->assertPageContainsText('Registration Portal');
    }

    /**
     * @When I register a new :tokenType token
     */
    public function registerNewToken(string $tokenType)
    {
        $this->minkContext->visit('/registration/select-token');

        switch ($tokenType) {
            case 'Yubikey':
                $this->minkContext->getSession()
                    ->getPage()
                    ->find('css', '[href="/registration/yubikey/prove-possession"]')->click();
                $this->minkContext->assertPageAddress('/registration/yubikey/prove-possession');
                $this->minkContext->assertPageContainsText('Link your YubiKey');
                $this->minkContext->fillField('ss_prove_yubikey_possession_otp', 'ccccccdhgrbtfddefpkffhkkukbgfcdilhiltrrncmig');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="ss_prove_yubikey_possession"]');
                $form->submit();
                break;
            case 'SMS':
                // Select the SMS second factor type
                $this->minkContext->getSession()
                    ->getPage()
                    ->find('css', '[href="/registration/sms/send-challenge"]')->click();
                $this->minkContext->assertPageAddress('/registration/sms/send-challenge');
                // Start registration
                $this->minkContext->assertPageContainsText('Send code');
                $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '612345678');
                $this->minkContext->pressButton('Send code');

                // Now we should be on the prove possession page where we enter our OTP
                $this->minkContext->assertPageAddress('/registration/sms/prove-possession');
                $this->minkContext->assertPageContainsText('Enter SMS code');
                $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '999');

                $this->minkContext->pressButton('Verify');
                break;
            case 'Demo GSSP':
                // Select the SMS second factor type
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[action="/registration/gssf/demo_gssp/authenticate"]');
                $form->submit();

                $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/registration');
                // Start registration
                $this->minkContext->assertPageContainsText('Register user');
                $this->minkContext->pressButton('Register user');

                // Pass through the demogssp
                $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/saml/sso_return');
                $this->minkContext->pressButton('Submit');
                // Pass through the gateway
                $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/gssp/demo_gssp/consume-assertion');
                $this->minkContext->pressButton('Submit');
                // Now we should be back at the SelfService
                break;
            default:
                throw new Exception(sprintf('The %s token type is not supported', $tokenType));
        }
    }

    /**
     * @When I verify my e-mail address
     */
    public function verifyEmailAddress()
    {
        $this->minkContext->visit(
            $this->getEmailVerificationUrl()
        );
    }

    /**
     * @When pass through GW
     */
    public function passThroughGW()
    {
        $this->minkContext->pressButton('Yes, continue');
        $this->minkContext->pressButton('Submit');
    }

    /**
     * @When I activate my token
     */
    public function activateToken()
    {
        $matches = [];
        preg_match('#/second-factor/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/vetting-types#', $this->minkContext->getSession()->getPage()->getContent(), $matches);
        if (empty($matches)) {
            throw new Exception('Could not find a valid second factor verification id in the url');
        }
        $href = reset($matches);

        $this->minkContext->getSession()
            ->getPage()
            ->find('css', '[href="'.$href.'"]')->click();
    }

    /**
     * @When I verify my e-mail address and choose the :vettingType vetting type
     */
    public function verifyEmailAddressAndChooseVettingType(string $vettingType)
    {
        ## And we should now be on the mail verification page
        $this->minkContext->assertPageContainsText('Verify your e-mail');
        $this->minkContext->assertPageContainsText('Check your inbox');

        $this->minkContext->visit(
            $this->getEmailVerificationUrl()
        );
        switch ($vettingType) {
            case "RA vetting":
                $url = $this->minkContext->getSession()->getCurrentUrl();
                if (strpos($url, '/registration-email-sent') === false) {
                    $this->iChooseToActivateMyTokenUsingServiceDeskVetting();
                }
                $this->minkContext->assertPageContainsText('Thank you for registering your token.');

                $page  = $this->minkContext->getSession()->getPage();
                $activationCodeCell = $page->find('xpath', '//th[text()="Activation code"]/../td');
                if (!$activationCodeCell) {
                    throw new Exception('Could not find a activation code table on the page');
                }

                $url  = $this->minkContext->getSession()->getCurrentUrl();
                $matches = [];
                preg_match('#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#', $url, $matches);
                if (empty($matches)) {
                    throw new Exception('Could not find a valid second factor verification id in the url');
                }
                $this->activationCode = $activationCodeCell->getText();
                $this->verifiedSecondFactorId = reset($matches);

                if (!preg_match('#[A-Z0-9]{8}#', $this->activationCode)) {
                    throw new Exception('Could not find a valid activation code');
                }
                break;
            case "Self Asserted Token registration":
                $this->iChooseToActivateMyTokenUsingSat();
                break;
            case "Self vetting":
                $this->iChooseToVetMyTokenMyself();
                break;
            default:
                throw new Exception(sprintf('Vetting type "%s" is not supported', $vettingType));
        }
    }

    /**
     * @When I choose the :vettingType vetting type
     */
    public function chooseVettingType(string $vettingType)
    {
        switch ($vettingType) {
            case "RA vetting":
                $this->iChooseToActivateMyTokenUsingServiceDeskVetting();
                $this->minkContext->assertPageContainsText('Thank you for registering your token.');

                $page  = $this->minkContext->getSession()->getPage();
                $activationCodeCell = $page->find('xpath', '//th[text()="Activation code"]/../td');
                if (!$activationCodeCell) {
                    throw new Exception('Could not find a activation code table on the page');
                }

                $url  = $this->minkContext->getSession()->getCurrentUrl();
                $matches = [];
                preg_match('#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#', $url, $matches);
                if (empty($matches)) {
                    throw new Exception('Could not find a valid second factor verification id in the url');
                }
                $this->activationCode = $activationCodeCell->getText();
                $this->verifiedSecondFactorId = reset($matches);

                if (!preg_match('#[A-Z0-9]{8}#', $this->activationCode)) {
                    throw new Exception('Could not find a valid activation code');
                }
                break;
            case "Self Asserted Token registration":
                $this->iChooseToActivateMyTokenUsingSat();
                break;
            default:
                throw new Exception(sprintf('Vetting type "%s" is not supported', $vettingType));
        }
    }

    /**
     * @Given I vet my :tokenType second factor in selfservice
     */
    public function iVetMySecondFactorInSelfService(string $tokenType)
    {
        $url = $this->minkContext->getSession()->getCurrentUrl();
        $matches = [];
        preg_match('#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#', $url, $matches);
        if (empty($matches)) {
            throw new Exception('Could not find a valid second factor verification id in the url');
        }
        $secondFactorId = reset($matches);
        $this->minkContext->assertPageAddress(sprintf('/second-factor/%s/new-recovery-token', $secondFactorId));

        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[name="safe-store"]');
        $form->submit();
        // Todo store the safe store password for later use?

        $this->minkContext->assertPageAddress(sprintf('/second-factor/%s/safe-store', $secondFactorId));
        // Promise we safely stored the secret
        $this->minkContext->checkOption('ss_promise_recovery_token_possession_promisedPossession');
        preg_match('#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}#', $url, $matches);
        if (empty($matches)) {
            throw new Exception('Could not find a valid second factor verification id in the url');
        }
        // Update the SF id, it now refers to the vetted second factor id
        $secondFactorId = reset($matches);
        $this->minkContext->pressButton('Continue');
        // We are back on the overview page. The revoke button is on the page (indicating the token was vetted)
        $this->minkContext->assertPageAddress('/overview');
        echo $secondFactorId;
        $this->minkContext->assertResponseContains(sprintf('/second-factor/vetted/%s/revoke', $secondFactorId));
        // The recovery token should also be present
        $this->minkContext->assertPageContainsText('Recovery methods');
        $this->minkContext->assertPageContainsText('Recovery code');
        $this->minkContext->assertResponseContains('/recovery-token/delete/');
    }

    public function iChooseToActivateMyTokenUsingServiceDeskVetting()
    {
        $this->minkContext->assertPageContainsText('Activate your token');
        $this->minkContext->pressButton('ra-vetting-button');
    }
    public function iChooseToActivateMyTokenUsingSAT()
    {
        $this->minkContext->assertPageContainsText('Activate your token yourself');
        $this->minkContext->pressButton('sat-button');
    }

    public function iChooseToVetMyTokenMyself()
    {
        $this->minkContext->assertPageContainsText('Use your existing token');
        $this->minkContext->pressButton('self-vet-button');
    }

    /**
     * @Then I can add an :recoveryTokenType recovery token using :tokenType
     */
    public function iCanAddAnRecoveryToken(string $recoveryTokenType, string $tokenType)
    {
        $this->minkContext->assertPageContainsText('Add recovery method');
        $this->minkContext->clickLink('Add recovery method');
        switch ($recoveryTokenType){
            case 'SMS':
                $this->minkContext->assertPageContainsText('You\'ll receive a text message with a verification code');
                $page = $this->minkContext->getSession()->getPage();
                $form = $page->find('css', 'form[name="sms"]');
                $form->submit();
                $this->provePossession($tokenType);
                // Now you need to register your SMS recovery token

                $this->minkContext->assertPageContainsText('Register an SMS recovery token');
                $this->minkContext->fillField('ss_send_sms_challenge_subscriber', '615056898');
                $this->minkContext->pressButton('Send code');

                $this->minkContext->assertPageAddress('/recovery-token/prove-sms-possession');
                $this->minkContext->assertPageContainsText('Enter the code that was sent to your phone');
                $this->minkContext->fillField('ss_verify_sms_challenge_challenge', '123456');
                $this->minkContext->pressButton('Verify');
                break;
            default:
                throw new Exception(sprintf('Recovery token type %s is not supported', $recoveryTokenType));
        }
    }

    private function provePossession(string $tokenType)
    {
        switch ($tokenType) {
            case "Demo GSSP":
                // We first need to prove we are in possession of our 2nd factor
                $this->minkContext->pressButton('Yes, continue');
                // Press the Authenticate button on the Demo authentication page
                $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/authentication');
                $this->minkContext->pressButton('button_authenticate');
                // Pass through the Demo Gssp redirection page.
                $this->minkContext->assertPageAddress('https://demogssp.dev.openconext.local/saml/sso_return');
                $this->minkContext->pressButton('Submit');
                // Pass through the 'return to sp' redirection page.
                $this->minkContext->assertPageAddress('https://gateway.dev.openconext.local/gssp/demo_gssp/consume-assertion');
                $this->minkContext->pressButton('Submit');

                break;
            case "Yubikey":
                $this->minkContext->pressButton('Yes, continue');
                $this->performYubikeyAuthentication();
                break;

            default:
                throw new Exception(sprintf('Prove possession is not yet supported for token type %s', $tokenType));
        }
    }

    /**
     * @Then I can not add a :recoveryTokenType recovery token
     */
    public function iCanNotAddARecoveryToken($recoveryTokenType)
    {
        $this->minkContext->visit('/overview');
        $this->minkContext->assertPageNotContainsText('Add recovery method');
    }

    /**
     * @Then :nofRecoveryTokens recovery tokens are activated
     */
    public function numberOfTokensRegistered(int $nofRecoveryTokens)
    {
        $page = $this->minkContext->getMink()->getSession()->getPage();
        $tokenTypes = $page->findAll('css', 'tr[data-test_tokentype]');

        if (empty($tokenTypes)) {
            throw new Exception('No active recovery tokens found on the page');
        }

        if (count($tokenTypes) != $nofRecoveryTokens) {
            throw new Exception(
                sprintf(
                    'Excpected to find %d recovery tokens on the page, actually found %d tokens',
                    $nofRecoveryTokens,
                    count($tokenTypes)
                )
            );
        }
    }

    private function performYubikeyAuthentication()
    {
        $this->minkContext->fillField('gateway_verify_yubikey_otp_otp', 'ccccccdhgrbtfddefpkffhkkukbgfcdilhiltrrncmig');
        $page = $this->minkContext->getSession()->getPage();
        $form = $page->find('css', 'form[name="gateway_verify_yubikey_otp"]');
        $form->submit();
        $this->minkContext->pressButton('Submit');
    }

    /**
     * @Given /^I visit the "([^"]*)" page in the selfservice portal$/
     */
    public function iVisitAPageInTheSelfServiceEnvironment($uri)
    {
        // We visit the SS location url
        $this->minkContext->visit($this->selfServiceUrl.'/'.$uri);
    }

    private function iSwitchLocaleTo(string $newLocale): void
    {
        $page = $this->minkContext->getSession()->getPage();
        $selectElement = $page->find('css', '#stepup_switch_locale_locale');
        $selectElement->selectOption($newLocale);
        $form = $page->find('css', 'form[name="stepup_switch_locale"]');
        $form->submit();
    }

    private function getEmailVerificationUrl()
    {
        $body = $this->getLastSentEmail();
        $body = str_replace("\r", '', $body);
        $body = str_replace("=\n", '', $body);
        $body = str_replace("=3D", '=', $body);

        if (!preg_match('#(https://selfservice.dev.openconext.local/verify-email\?n=[a-f0-9]+)#', $body, $matches)) {
            throw new Exception('Unable to find email verification link in message');
        }

        return $matches[1];
    }

    private function getLastSentEmail()
    {
        $response = file_get_contents($this->mailCatcherUrl);

        if (!$response) {
            throw new Exception(
                'Unable to read e-mail - is mailcatcher active?'
            );
        }

        $messages = json_decode($response);
        if (!is_array($messages)) {
            throw new Exception(
                'Unable to parse mailcatcher response'
            );
        }

        if (empty($messages)) {
            throw new Exception(
                'No mail received by mailcatcher!'
            );
        }

        $firstMessage = array_pop($messages);

        return $this->getEmailById(
            $firstMessage->id
        );
    }


    private function getEmailById($id)
    {
        $response = file_get_contents(
            sprintf(
                '%s/%d.html',
                rtrim($this->mailCatcherUrl, '/'),
                $id
            )
        );

        if (!$response) {
            throw new Exception(
                'Unable to read e-mail message - is mailcatcher active?'
            );
        }

        return $response;
    }

    /**
     * @return string
     */
    public function getActivationCode()
    {
        return $this->activationCode;
    }

    /**
     * @return string
     */
    public function getVerifiedSecondFactorId()
    {
        return $this->verifiedSecondFactorId;
    }

    private function diePrintingContent()
    {
        echo $this->minkContext->getSession()->getCurrentUrl();
        echo $this->minkContext->getSession()->getPage()->getContent();
        die;
    }
}
