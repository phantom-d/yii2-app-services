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
            if ($this->module && !($this->module instanceof \yii\base\Application)) {
                $class = new \ReflectionClass($this->module);
                $this->defaultNamespace = $class->getNamespaceName();
            }

            $this->defaultNamespace .= ($this->id ? '\\' . $this->id : '');
        }
        if ($this->namespace === null) {
            if ($this->module !== null) {
                if (!($this->module instanceof \yii\base\Application)) {
                    $class = new \ReflectionClass($this->module);
                    $this->namespace = $class->getNamespaceName() . '\\';
                }
            }
            $appPath  = explode('/', Yii::getAlias('@app'));
            $this->namespace .= end($appPath)
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
                    $reflector  = new \ReflectionClass($class);
                    /* @var $parameters \ReflectionParameter */
                    $parameters = $reflector->getMethod('__construct')->getParameters();
                    if (count($parameters) > 1) {
                        $params = (array)$params;
                        $args   = [];
                        foreach ($parameters as $index => $param) {
                            $key = $param->getName();
                            $args[$key] = null;
                            if (isset($params[$key])) {
                                $args[$key] = $params[$key];
                                unset($params[$key]);
                            } elseif (isset($params[$index])) {
                                $args[$key] = $params[$index];
                                unset($params[$index]);
                            } else {
                                if ($param->isOptional()) {
                                    $args[$key] = $param->getDefaultValue();
                                }
                            }
                        }
                        if (false === empty($params)) {
                            $args['config'] = $params;
                        }
                        return $reflector->newInstanceArgs($args);
                    } else {
                        return new $class($params);
                    }
                }
                return \yii\di\Instance::ensure($params, $class);
            }

            if ($strict) {
                $message = Yii::t('yii', 'Calling unknown class: {class}', ['class' => $class]);
                throw new UnknownClassException($message);
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
            $parts = explode('-', Inflector::camel2id($name));

            $names  = [];
            /* @var $object \modules\BaseService */
            $object = null;

            while (count($parts)) {
                $lastPart = array_pop($parts);
                array_unshift($names, $lastPart);

                $classParts = Inflector::id2camel(implode('-', $parts));

                $class  = ucfirst($classParts);
                if ($object = $this->getObject($class, [], false)) {
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
