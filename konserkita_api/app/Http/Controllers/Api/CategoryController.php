<?php

namespace App\Http\Controllers\Api;

use App\Models\EventCategory;
use Illuminate\Http\Request;

class CategoryController extends BaseController
{
    public function index()
    {
        $categories = EventCategory::where('status', 'active')->get();
        return $this->sendResponse($categories, 'Categories retrieved successfully.');
    }
}
