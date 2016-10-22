<?php
defined('YII_DEBUG') or define('YII_DEBUG', true);
defined('YII_ENV') or define('YII_ENV', 'dev');

require(__DIR__ . '/../../vendor/autoload.php');
require(__DIR__ . '/../../vendor/yiisoft/yii2/Yii.php');
require(__DIR__ . '/../../common/config/bootstrap.php');
require(__DIR__ . '/../config/bootstrap.php');

if (!YII_ENV_TEST && extension_loaded('xhprof')) {
    xhprof_enable(XHPROF_FLAGS_CPU + XHPROF_FLAGS_MEMORY);
}

$config = yii\helpers\ArrayHelper::merge(
    require(__DIR__ . '/../../common/config/main.php'),
    require(__DIR__ . '/../../common/config/main-local.php'),
    require(__DIR__ . '/../config/main.php'),
    require(__DIR__ . '/../config/main-local.php')
);

$application = new yii\web\Application($config);
$application->run();

if (!YII_ENV_TEST && extension_loaded('xhprof')) {
    $xhprofData  = xhprof_disable();

    include_once __DIR__ . "/../../../xhprof/xhprof_lib/utils/xhprof_lib.php";
    include_once __DIR__ . "/../../../xhprof/xhprof_lib/utils/xhprof_runs.php";

    $xhprofRuns = new XHProfRuns_Default();

    $xhprofUri = ltrim($_SERVER['REQUEST_URI'], '/');
    $xhprofKey = str_replace(
        ['/', '.', '?', '&', ':'], //
        ['_', '-', '~', ';', '@'], //
        $_SERVER['REQUEST_METHOD']
        . (Yii::$app->request->isAjax ? '--AJAX' : '')
        . '--' . $_SERVER['HTTP_HOST']
        . ($xhprofUri ? '_' . urldecode($xhprofUri) : '')
    );

    $runId = $xhprofRuns->save_run($xhprofData, $xhprofKey);
}
