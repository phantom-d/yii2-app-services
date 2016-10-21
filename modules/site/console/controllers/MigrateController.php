<?php

namespace modules\site\console\controllers;

/**
 * Class MigrateController.
 *
 * @inheritdoc
 */
class MigrateController extends \yii\console\controllers\MigrateController
{

    /**
     * @var string Имя таблицы в которой будут сохранена история миграций
     */
    public $migrationTable = '{{%db_migration_site}}';

    /**
     * @var string Путь к файлами миграций
     */
    public $migrationPath  = '@modules/site/migrations';

}
