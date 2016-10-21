<?php

return [
    'bootstrap'  => ['log'],
    'vendorPath' => dirname(dirname(__DIR__)) . '/vendor',
    'aliases'    => [
        '@bower' => '@vendor/bower-asset',
        '@npm'   => '@vendor/npm-asset',
    ],
    'components' => [
        'cache' => [
            'class' => 'yii\caching\FileCache',
        ],
        'services' => [
            'class' => 'modules\Services',
        ],
    ],
    'modules'    => [
        'site' => [
            'class' => 'modules\site\Module'
        ],
    ],
];
