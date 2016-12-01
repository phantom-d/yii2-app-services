<?php

namespace modules;

use Yii;

/**
 * Class Module - Base class for working with users modules
 * 
 * @property \modules\Services $services Object for working with service layer
 */
class Module extends \yii\base\Module
{

    /**
     * @inheritdoc
     */
    public function init()
    {
        if ($this->controllerNamespace === null) {
            $class = get_class($this);
            if (($pos   = strrpos($class, '\\')) !== false) {
                $appPath = explode('/', Yii::getAlias('@app'));
                $this->controllerNamespace = substr($class, 0, $pos)
                    . '\\' . end($appPath)
                    . '\\controllers';
            }
        }


        $viewPath = $this->getViewPath();
        $appPath  = explode('/', Yii::getAlias('@app'));
        $viewPath .= DIRECTORY_SEPARATOR . end($appPath);

        if (isset(\Yii::$app->view->theme)) {
            $viewPath = $this->getBasePath();
        }

        $this->setViewPath($viewPath);
    }

    /**
     * Get object for working with module service layer
     *
     * @param array $params Services interface parameters
     * @return type
     */
    public function getServices($params = [])
    {
        $params = \yii\helpers\ArrayHelper::merge(
            [
                'class'  => '\modules\Services',
                'module' => &$this,
            ],
            $params
        );
        return \yii\di\Instance::ensure($params);
    }

}
