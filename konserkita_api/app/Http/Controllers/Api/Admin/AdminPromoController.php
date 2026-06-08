<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\PromoCode;
use Illuminate\Http\Request;
use App\Services\AdminAuditService;

class AdminPromoController extends BaseController
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
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

        $this->auditService->log(
            auth()->user(),
            'promo_created',
            'promos',
            $promo,
            null,
            $promo->toArray(),
            "Created promo code: {$promo->code}"
        );

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

        $oldValues = $promo->toArray();
        $promo->update($validated);

        $this->auditService->log(
            auth()->user(),
            'promo_updated',
            'promos',
            $promo,
            $oldValues,
            $promo->toArray(),
            "Updated promo code: {$promo->code}"
        );

        return $this->sendResponse($promo, 'Promo code updated successfully.');
    }

    public function destroy($id)
    {
        $promo = PromoCode::find($id);
        if (!$promo) {
            return $this->sendError('Promo code not found', [], 404);
        }

        $oldValues = $promo->toArray();
        $promo->delete();

        $this->auditService->log(
            auth()->user(),
            'promo_deleted',
            'promos',
            $promo,
            $oldValues,
            null,
            "Deleted promo code: {$promo->code}"
        );

        return $this->sendResponse([], 'Promo code deleted successfully.');
    }
}
