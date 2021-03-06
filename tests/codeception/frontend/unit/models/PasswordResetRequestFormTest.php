<?php

namespace tests\codeception\frontend\unit\models;

use Yii;
use tests\codeception\frontend\unit\DbTestCase;
use tests\codeception\common\fixtures\UserFixture;
use Codeception\Specify;

class PasswordResetRequestFormTest extends DbTestCase
{

    use Specify;

    protected function setUp()
    {
        parent::setUp();

        Yii::$app->mailer->fileTransportCallback = function ($mailer, $message) {
            return 'testing_message.eml';
        };
    }

    protected function tearDown()
    {
        @unlink($this->getMessageFile());

        parent::tearDown();
    }

    public function testSendEmailWrongUser()
    {
        $this->specify('no user with such email, message should not be sent', function () {
            /* @var $model \modules\site\models\PasswordResetRequestForm */
            $model = \Yii::$app
                ->getModule('site')
                ->services
                ->getObject('site')
                ->models
                ->getObject('PasswordResetRequestForm');

            $model->email = 'not-existing-email@example.com';

            expect('email not sent', $model->sendEmail())->false();
        });

        $this->specify('user is not active, message should not be sent', function () {
            /* @var $model \modules\site\models\PasswordResetRequestForm */
            $model = \Yii::$app->getModule('site')
                ->services
                ->getObject('site')
                ->models
                ->getObject('PasswordResetRequestForm');

            $model->email = $this->user[1]['email'];

            expect('email not sent', $model->sendEmail())->false();
        });
    }

    public function testSendEmailCorrectUser()
    {
        /* @var $model \modules\site\models\PasswordResetRequestForm */
        $model = \Yii::$app
            ->getModule('site')
            ->services
            ->getObject('site')
            ->models
            ->getObject('PasswordResetRequestForm');

        $model->email = $this->user[0]['email'];

        /* @var $user \common\models\User */
        $user = \Yii::$app
            ->services
            ->getObject('user')
            ->models
            ->getObject('user')
            ->findOne(['password_reset_token' => $this->user[0]['password_reset_token']]);

        expect('email sent', $model->sendEmail())->true();
        expect('user has valid token', $user->password_reset_token)->notNull();

        $this->specify('message has correct format', function () use ($model) {

            expect('message file exists', file_exists($this->getMessageFile()))->true();

            $message = file_get_contents($this->getMessageFile());
            expect('message "from" is correct', $message)->contains(Yii::$app->params['supportEmail']);
            expect('message "to" is correct', $message)->contains($model->email);
        });
    }

    public function fixtures()
    {
        return [
            'user' => [
                'class'    => UserFixture::className(),
                'dataFile' => '@tests/codeception/frontend/unit/fixtures/data/models/user.php'
            ],
        ];
    }

    private function getMessageFile()
    {
        return Yii::getAlias(Yii::$app->mailer->fileTransportPath) . '/testing_message.eml';
    }

}
