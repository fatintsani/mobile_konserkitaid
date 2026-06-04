<?php

namespace App\Http\Controllers\Api;

use App\Models\Banner;
use Illuminate\Http\Request;

class BannerController extends BaseController
{
    public function index()
    {
        $banners = Banner::where('status', 'active')
            ->where(function ($query) {
                $query->whereNull('start_date')
                      ->orWhere('start_date', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('end_date')
                      ->orWhere('end_date', '>=', now());
            })
            ->get();
            
        return $this->sendResponse($banners, 'Banners retrieved successfully.');
    }
}
