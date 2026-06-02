<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EmployeeController;

Route::get('/', function () {
    return redirect()->route('employees.index');
});

Route::get('/health', function () {
    return response('OK', 200);
});

Route::resource('employees', EmployeeController::class);
