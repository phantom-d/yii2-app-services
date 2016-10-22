<?php

namespace tests\codeception\frontend\unit\models;

use tests\codeception\frontend\unit\DbTestCase;
use tests\codeception\common\fixtures\UserFixture;
use frontend\models\ResetPasswordForm;

class ResetPasswordFormTest extends DbTestCase
{

    /**
     * @expectedException \yii\base\InvalidParamException
     */
    public function testResetWrongToken()
    {
        \Yii::$app->getModule('site')
            ->services
            ->getObject('site')
            ->models
            ->getObject('ResetPasswordForm', 'notexistingtoken_1391882543');
    }

    /**
     * @expectedException \yii\base\InvalidParamException
     */
    public function testResetEmptyToken()
    {
        \Yii::$app->getModule('site')
            ->services
            ->getObject('site')
            ->models
            ->getObject('ResetPasswordForm');
    }

    public function testResetCorrectToken()
    {
        $form = \Yii::$app->getModule('site')
            ->services
            ->getObject('site')
            ->models
            ->getObject('ResetPasswordForm', $this->user[0]['password_reset_token']);
        expect('password should be resetted', $form->resetPassword())->true();
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

}
