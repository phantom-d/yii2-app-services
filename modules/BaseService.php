<?php

namespace modules;

use yii\base\Component;

/**
 * Class BaseService - Base class for service layer classes
 *
 * @property \modules\Models $models Object for access to module models
 * 
 * @author Anton Ermolovich <a.ermolovich@babadu.ru>
 */
class BaseService extends Component implements ServiceInterface
{

    /**
     * @var \modules\Module|\yii\web\Application|\yii\console\Application Parent module
     */
    public $module;

    /**
     * Get object for working with module data layer
     *
     * @return \modules\Models
     */
    public function getModels()
    {
        $params = [
            'class'  => '\modules\Models',
            'module' => &$this->module,
        ];
        return \yii\di\Instance::ensure($params);
    }

}
