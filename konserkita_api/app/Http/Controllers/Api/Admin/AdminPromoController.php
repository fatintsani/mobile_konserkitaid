<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\PromoCode;
use Illuminate\Http\Request;

class AdminPromoController extends BaseController
{
    public function index()
    {
        $promos = PromoCode::orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($promos, 'Promo codes retrieved successfully.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:promo_codes,code|max:50',
            'description' => 'nullable|string',
            'discount_type' => 'required|in:fixed,percentage',
            'discount_value' => 'required|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'quota' => 'required|integer|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'status' => 'required|in:active,inactive',
        ]);

        $promo = PromoCode::create($validated);
        return $this->sendResponse($promo, 'Promo code created successfully.');
    }

    public function update(Request $request, $id)
    {
        $promo = PromoCode::find($id);
        if (!$promo) {
            return $this->sendError('Promo code not found', [], 404);
        }

        $validated = $request->validate([
            'code' => 'required|string|max:50|unique:promo_codes,code,' . $id,
            'description' => 'nullable|string',
            'discount_type' => 'required|in:fixed,percentage',
            'discount_value' => 'required|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'quota' => 'required|integer|min:0',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'status' => 'required|in:active,inactive',
        ]);

        $promo->update($validated);
        return $this->sendResponse($promo, 'Promo code updated successfully.');
    }

    public function destroy($id)
    {
        $promo = PromoCode::find($id);
        if (!$promo) {
            return $this->sendError('Promo code not found', [], 404);
        }

        $promo->delete();
        return $this->sendResponse([], 'Promo code deleted successfully.');
    }
}
