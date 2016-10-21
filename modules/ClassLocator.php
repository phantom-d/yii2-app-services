<?php

namespace modules;

use Yii;
use yii\base\Component;
use yii\helpers\Inflector;
use yii\base\UnknownClassException;
use yii\base\UnknownMethodException;

/**
 * Abstract class ClassLocator - Base class for working with module layers
 * 
 * @author Anton Ermolovich <a.ermolovich@babadu.ru>
 */
abstract class ClassLocator extends Component
{

    /**
     * @var string Component ID
     */
    public $id = '';

    /**
     * @var string Default namespace
     */
    public $defaultNamespace;

    /**
     * @var string Current namespace
     */
    public $namespace;

    /**
     * @var \modules\Module|\yii\web\Application|\yii\console\Application Parent module
     */
    public $module;

    /**
     * @var string Suffix for class name
     */
    protected $suffix = '';

    /**
     * @inheritdoc
     */
    public function init()
    {
        if ($this->defaultNamespace === null) {
            $this->defaultNamespace = 'common';
            if ($this->module) {
                $class = new \ReflectionClass($this->module);
                $this->defaultNamespace = $class->getNamespaceName();
            }

            $this->defaultNamespace .= ($this->id ? '\\' . $this->id : '');
        }
        if ($this->namespace === null) {
            if ($this->module !== null) {
                $class = new \ReflectionClass($this->module);
                $this->namespace = $class->getNamespaceName() . '\\';
            }
            $this->namespace .= end(explode('/', Yii::getAlias('@app')))
                . ($this->id ? '\\' . $this->id : '');
        }
        if (null === $this->module) {
            $this->module = &Yii::$app;
        }
        parent::init();
    }

    /**
     * Get module service/model object
     *
     * @param string $name Class name
     * @param array $params Class parameters
     *
     * @return \yii\base\Object
     *
     * @throws \yii\base\UnknownClassException
     */
    public function getObject($name, $params = [], $strict = true)
    {
        $className = '\\' . Inflector::id2camel($name, '_') . strval($this->suffix);
        $class     = $this->namespace . $className;

        if (false === class_exists($class)) {
            $class = $this->defaultNamespace . $className;
        }

        if (class_exists($class)) {
            if ($this instanceof \modules\Services) {
                if (false === isset($params['module'])) {
                    $params['module'] = &$this->module;
                }
            } else {
                if ($params) {
                    return new $class($params);
                }
            }
            return \yii\di\Instance::ensure($params, $class);
        }

        if ($strict) {
            $message = Yii::t('yii', 'Calling unknown class: {class}', ['class' => $class]);
            throw new UnknownClassException($message);
        }

        return null;
    }

    /**
     * @inheritdoc
     */
    public function __call($name, $params)
    {
        try {
            $parts = explode('-', Inflector::camel2id($name));

            $names  = [];
            /* @var $object \modules\BaseService */
            $object = null;

            while (count($parts)) {
                array_unshift($names, array_pop($parts));

                $class  = ucfirst(Inflector::id2camel(implode('-', $parts)));
                if ($object = $this->getObject($class, [], false)) {
                    break;
                }
            }

            if (empty($object)) {
                $message = Yii::t('yii', 'Not found model class: {class}', ['class' => $name]);
                throw new UnknownClassException($message);
            }

            $method = lcfirst(Inflector::id2camel(implode('-', $names)));

            if ($method && method_exists($object, $method)) {
                return call_user_func_array([$object, $method], $params);
            }

            $message = Yii::t(
                    'yii', //
                    'Calling unknown method: {class}::{method}', //
                    ['class' => $object->className(), 'method' => $method,]
            );

            throw new UnknownMethodException($message);
        } catch (\Exception $e) {
            Yii::$app->getErrorHandler()->handleException($e);
        }
    }

}
