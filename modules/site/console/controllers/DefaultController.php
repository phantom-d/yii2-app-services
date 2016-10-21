<?php

namespace modules\site\console\controllers;

use yii\console\Controller;

/**
 * Default controller for the `site` module
 */
class DefaultController extends Controller
{

    /**
     * Renders the index view for the module
     * @return string
     */
    public function actionIndex()
    {
        $this->module->services->getObject('site');
    }

}
