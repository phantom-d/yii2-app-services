<?php

namespace modules\site\backend;

use yii\base\BootstrapInterface;

class Bootstrap implements BootstrapInterface
{

    /**
     * @inheritdoc
     */
    public function bootstrap($app)
    {
        $app->getUrlManager()->addRules(
            [
            ''                             => 'site/default/index',
            'site/<action:[a-zA-Z0-9_-]+>' => 'site/default/<action>',
            ]
        );
    }

}
