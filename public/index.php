<?php

use App\Kernel;
use Runtime\Swoole\Runtime;
use Swoole\Constant;

if (isset($_ENV['SWOOLE']) && $_ENV['SWOOLE'] === '1') {
    $_SERVER['APP_RUNTIME'] = Runtime::class;
    $_SERVER['APP_RUNTIME_OPTIONS'] = [
        'host' => '0.0.0.0',
        'port' => 8000,
        'mode' => SWOOLE_BASE,
        'settings' => [
            Constant::OPTION_WORKER_NUM => 16,
            Constant::OPTION_ENABLE_STATIC_HANDLER => true,
            Constant::OPTION_DOCUMENT_ROOT => dirname(__DIR__).'/public'
        ],
    ];
}

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context) {
    return new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);
};
