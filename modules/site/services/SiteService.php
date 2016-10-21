<?php

namespace modules\site\services;

use Yii;
use yii\data\ActiveDataProvider;

/**
 * Class SiteService - Site service
 *
 * @author Anton Ermolovich <a.ermolovich@babadu.ru>
 */
class SiteService extends \modules\BaseService
{

    /**
     * Contact form
     *
     * @param array $data Post data
     * @return array
     */
    public function contactForm($data = [])
    {
        $return = false;
        $model  = $this->models->getObject('ContactForm');
        if ($model->load($data) && $model->validate()) {
            if ($model->sendEmail(Yii::$app->params['adminEmail'])) {
                $message = 'Thank you for contacting us. We will respond to you as soon as possible.';
                Yii::$app->session->setFlash('success', $message);
            } else {
                Yii::$app->session->setFlash('error', 'There was an error sending email.');
            }

            $return = true;
        }
        return [
            'view'   => [
                'model' => $model,
            ],
            'result' => $return,
        ];
    }

    /**
     * Login form
     *
     * @param array $data Post data
     * @return array
     */
    public function loginForm($data = [])
    {
        $return = false;
        $model  = $this->models->getObject('LoginForm');
        if ($model->load($data) && $model->login()) {
            $return = true;
        }
        return [
            'view'   => [
                'model' => $model,
            ],
            'result' => $return,
        ];
    }

    /**
     * Signup form
     *
     * @param array $data Post data
     * @return array
     */
    public function signupForm($data = [])
    {
        $return = false;
        $model  = $this->models->getObject('SignupForm');
        if ($model->load($data)) {
            if ($user = $model->signup()) {
                if (Yii::$app->getUser()->login($user)) {
                    $return = true;
                }
            }
        }
        return [
            'view'   => [
                'model' => $model,
            ],
            'result' => $return,
        ];
    }

    /**
     * Request for password reset
     *
     * @param array $data Post data
     * @return array
     */
    public function requestPasswordReset($data = [])
    {
        $return = false;
        $model  = $this->models->getObject('PasswordResetRequestForm');
        if ($model->load($data) && $model->validate()) {
            if ($model->sendEmail()) {
                Yii::$app->session->setFlash('success', 'Check your email for further instructions.');
                $return = true;
            } else {
                Yii::$app->session->setFlash('error', 'Sorry, we are unable to reset password for email provided.');
            }
        }
        return [
            'view'   => [
                'model' => $model,
            ],
            'result' => $return,
        ];
    }

    /**
     * Reset password form
     *
     * @param string $token Token
     * @param array $data Post data
     * @return array
     */
    public function resetPassword($token, $data = [])
    {
        $return = false;
        $model  = $this->models->getObject('ResetPasswordForm', $token);

        if ($model->load($data) && $model->validate() && $model->resetPassword()) {
            Yii::$app->session->setFlash('success', 'New password was saved.');
            $return = true;
        }
        return [
            'view'   => [
                'model' => $model,
            ],
            'result' => $return,
        ];
    }

}
