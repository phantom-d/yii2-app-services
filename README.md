Yii 2 Services Project Template
===============================

Yii 2 Services Project Template is a skeleton [Yii 2](http://www.yiiframework.com/) application best for
developing complex Web applications with multiple tiers.

The template includes three tiers: front end, back end, and console, each of which
is a separate Yii application.

The template is designed to work in a team development environment. It supports
deploying the application in different environments.

Documentation is at [docs/guide/README.md](docs/guide/README.md).

[![Latest Stable Version](https://poser.pugx.org/phantom-d/yii2-app-services/v/stable.png)](https://packagist.org/packages/phantom-d/yii2-app-services)
[![Total Downloads](https://poser.pugx.org/phantom-d/yii2-app-services/downloads.png)](https://packagist.org/packages/phantom-d/yii2-app-services)
[![License](https://poser.pugx.org/clippings/phantom-pdf/license)](https://packagist.org/packages/clippings/phantom-pdf)
[![Build Status](https://travis-ci.org/phantom-d/yii2-app-services.svg?branch=2.0.10)](https://travis-ci.org/phantom-d/yii2-app-services)

DIRECTORY STRUCTURE
-------------------

```
common
    config/              contains shared configurations
    mail/                contains view files for e-mails
    models/              contains model classes used in backend, frontend and console
    services/            contains service classes used in backend, frontend and console
console
    config/              contains console configurations
    controllers/         contains console controllers (commands)
    migrations/          contains database migrations
    models/              contains console-specific model classes
    services/            contains console-specific service classes
    runtime/             contains files generated during runtime
backend
    assets/              contains application assets such as JavaScript and CSS
    config/              contains backend configurations
    controllers/         contains Web controller classes
    models/              contains backend-specific model classes
    services/            contains backend-specific service classes
    runtime/             contains files generated during runtime
    views/               contains view files for the Web application
    web/                 contains the entry script and Web resources
frontend
    assets/              contains application assets such as JavaScript and CSS
    config/              contains frontend configurations
    controllers/         contains Web controller classes
    models/              contains frontend-specific model classes
    services/            contains frontend-specific service classes
    runtime/             contains files generated during runtime
    views/               contains view files for the Web application
    web/                 contains the entry script and Web resources
    widgets/             contains frontend widgets
modules/                 contains modules
    module
        console
            controllers/    contains console controllers (commands) of module
            models/         contains console-specific model classes of module
            services/       contains console-specific service classes of module
        backend
            controllers/    contains Web controller classes in backend of module
            models/         contains backend-specific model classes of module
            services/       contains service classes used in backend of module
        frontend
            controllers/    contains Web controller classes in frontend of module
            models/         contains frontend-specific model classes of module
            services/       contains service classes used in frontend of module
        models/             contains module-specific model classes
        services/           contains module-specific service classes
        views/               
            backend/        contains backend-specific view files for the Web application of module
            frontend        contains frontend-specific view files for the Web application of module
        widgets/            contains frontend widgets
vendor/                  contains dependent 3rd-party packages
environments/            contains environment-based overrides
tests                    contains various tests for the advanced application
    codeception/         contains tests developed with Codeception PHP Testing Framework
```
