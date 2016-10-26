<?php

namespace modules\site\frontend;

use yii\base\BootstrapInterface;

class Bootstrap implements BootstrapInterface
{

    /**
     * @inheritdoc
     * @param \yii\web\Application $app the application currently running
     */
    public function bootstrap($app)
    {
        $app->getUrlManager()->addRules([
            ''                             => 'site/default/index',
            'site/<action:[a-zA-Z0-9_-]+>' => 'site/default/<action>',
            'site/<action:[a-zA-Z0-9_-]+>/<token:[a-zA-Z0-9_-]+>' => 'site/default/<action>',
        ]);
    }

}
