<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\Schema;

Schema::table('event_categories', function($table) {
    if (Schema::hasColumn('event_categories', 'slug')) {
        $table->dropColumn('slug');
    }
    if (Schema::hasColumn('event_categories', 'description')) {
        $table->dropColumn('description');
    }
    if (Schema::hasColumn('event_categories', 'status')) {
        $table->dropColumn('status');
    }
});
