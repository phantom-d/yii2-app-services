<?php

namespace tests\codeception\frontend\unit\models;

use Yii;
use tests\codeception\frontend\unit\TestCase;
use frontend\models\ContactForm;
use Codeception\Specify;

class ContactFormTest extends TestCase
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
        if (file_exists($file = $this->getMessageFile())) {
            unlink($file);
        }
        parent::tearDown();
    }

    public function testContact()
    {
        /* @var $model \modules\site\models\ContactForm */
        $model = \Yii::$app->getModule('site')
            ->services
            ->getObject('site')
            ->models
            ->getObject('ContactForm');

        $model->attributes = [
            'name'    => 'Tester',
            'email'   => 'tester@example.com',
            'subject' => 'very important letter subject',
            'body'    => 'body of current message',
        ];

        $model->sendEmail('admin@example.com');

//        $this->specify('email should be send', function () {
//            expect('email file should exist', file_exists($this->getMessageFile()))->true();
//        });
//
//        $this->specify('message should contain correct data', function () use ($model) {
//            $emailMessage = file_get_contents($this->getMessageFile());
//
//            expect('email should contain user name', $emailMessage)->contains($model->name);
//            expect('email should contain sender email', $emailMessage)->contains($model->email);
//            expect('email should contain subject', $emailMessage)->contains($model->subject);
//            expect('email should contain body', $emailMessage)->contains($model->body);
//        });
    }

    private function getMessageFile()
    {
        return Yii::getAlias(Yii::$app->mailer->fileTransportPath) . '/testing_message.eml';
    }

}
