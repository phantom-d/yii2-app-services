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
     * @var boolean Search class throw parent module
     */
    public $throwParents = false;

    /**
     * @var string Suffix for class name
     */
    protected $suffix = '';

    /**
     * @var boolean Get object with exception
     */
    private $_strict = true;

    /**
     * @inheritdoc
     */
    public function init()
    {
        if ($this->defaultNamespace === null) {
            $this->defaultNamespace = 'common';
            if ($this->module) {
                $class = $this->module->className();
                $this->defaultNamespace = mb_substr($class, 0, mb_strrpos($class, '\\'));
            }
            $this->defaultNamespace .= ($this->id ? '\\' . $this->id : '');
        }
        if ($this->namespace === null) {
            if ($this->module) {
                $class = $this->module->className();
                $this->namespace = mb_substr($class, 0, mb_strrpos($class, '\\')) . '\\';
            }
            $appPath = explode('/', Yii::getAlias('@app'));

            $this->namespace .= end($appPath)
                . ($this->id ? '\\' . $this->id : '');
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
    public function getObject($name, $params = [])
    {
        try {
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
                    $args = func_get_args();
                    array_shift($args);
                    if (1 === count($args)) {
                        return new $class($params);
                    } else {
                        $reflector  = new \ReflectionClass($class);
                        if (empty($args)) {
                            /* @var $parameters \ReflectionParameter */
                            $parameters = $reflector->getMethod('__construct')->getParameters();
                            foreach ($parameters as $value) {
                                $args[] = $value->isOptional() ? $value->getDefaultValue() : null;
                            }
                        }
                        return $reflector->newInstanceArgs($args);
                    }
                }
                return \yii\di\Instance::ensure($params, $class);
            }

            if ($this->_strict) {
                $message = Yii::t('yii', 'Calling unknown class: {class}', ['class' => $class]);
                throw new UnknownClassException($message);
            } else {
                $this->_strict = true;
            }
        } catch (\Exception $e) {
            throw $e;
        }

        return null;
    }

    /**
     * @inheritdoc
     */
    public function __call($name, $params)
    {
        try {
            $component = ($this instanceof \modules\Services) ? 'services' : 'models';

            $parts = explode('-', Inflector::camel2id($name));

            $names  = [];
            /* @var $object \modules\Service */
            $object = null;

            while (count($parts)) {
                $lastPart = array_pop($parts);
                array_unshift($names, $lastPart);

                $classParts = Inflector::id2camel(implode('-', $parts));

                $class = ucfirst($classParts);
                $this->_strict = false;
                if ($object = $this->getObject($class)) {
                    break;
                }
            }

            if (empty($object)) {
                $message = Yii::t('yii', 'Not found model class: {class}', ['class' => $name]);
                throw new UnknownClassException($message);
            }

            $methodParts = Inflector::id2camel(implode('-', $names));

            $method = lcfirst($methodParts);

            if ($method && method_exists($object, $method)) {
                return call_user_func_array([$object, $method], $params);
            }

            if ($this->throwParents && $this->module) {
                return call_user_func_array([$this->module->{$component}, $name], $params);
            }

            $message = Yii::t(
                    'yii', //
                    'Calling unknown method: {class}::{method}', //
                    ['class' => $object->className(), 'method' => $method,]
            );

            throw new UnknownMethodException($message);
        } catch (\Exception $e) {
            throw $e;
        }
    }

}
