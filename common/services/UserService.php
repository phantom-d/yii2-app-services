<?php

namespace common\services;

use Yii;

/**
 * Class SiteService - Site service
 *
 * @author Anton Ermolovich <a.ermolovich@babadu.ru>
 */
class UserService extends \modules\Service
{

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

}
