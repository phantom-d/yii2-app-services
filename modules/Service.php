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
class Service extends Component implements ServiceInterface
{

    /**
     * @var \modules\Module|\yii\web\Application|\yii\console\Application Parent module
     */
    public $module;

    /**
     * Get object for working with module data layer
     *
     * @param array $params Models interface parameters
     * @return \modules\Models
     */
    public function getModels($params = [])
    {
        $params = \yii\helpers\ArrayHelper::merge(
            [
                'class'  => '\modules\Models',
                'module' => &$this->module,
                'throwParents' => ($this->module) ? $this->module->services->throwParents : false,
            ],
            $params
        );
        return \yii\di\Instance::ensure($params);
    }

}
