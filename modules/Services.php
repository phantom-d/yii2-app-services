<?php

namespace modules;

use Yii;

/**
 * Class Services - Класс для работы с сервисным слоем (бизнес логика)
 *
 * @property \modules\Models $models Object for working with data layer
 *
 * @author Anton Ermolovich <a.ermolovich@babadu.ru>
 */
class Services extends ClassLocator
{

    /**
     * @var string Component ID
     */
    public $id = 'services';

    /**
     * @inheritdoc
     */
    protected $suffix = 'Service';

}
