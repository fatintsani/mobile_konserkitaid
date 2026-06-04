<?php

namespace App\Http\Controllers\Api;

use App\Models\PromoCode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class PromoController extends BaseController
{
    public function validateCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required|string',
            'subtotal' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 422);
        }

        $promo = PromoCode::where('code', $request->promo_code)
            ->where('status', 'active')
            ->first();

        if (!$promo) {
            return $this->sendError('Promo code not found or inactive.', [], 404);
        }

        $now = Carbon::now();
        if ($promo->start_date && $now->lt($promo->start_date)) {
            return $this->sendError('Promo code is not active yet.', [], 400);
        }

        if ($promo->end_date && $now->gt($promo->end_date)) {
            return $this->sendError('Promo code has expired.', [], 400);
        }

        if ($promo->used >= $promo->quota) {
            return $this->sendError('Promo code quota exceeded.', [], 400);
        }

        $subtotal = $request->subtotal;
        $discountAmount = 0;

        if ($promo->discount_type === 'percentage') {
            $discountAmount = ($promo->discount_value / 100) * $subtotal;
            if ($promo->max_discount && $discountAmount > $promo->max_discount) {
                $discountAmount = $promo->max_discount;
            }
        } else {
            $discountAmount = $promo->discount_value;
        }

        if ($discountAmount > $subtotal) {
            $discountAmount = $subtotal; // Can't be negative
        }

        $finalTotal = $subtotal - $discountAmount;

        return $this->sendResponse([
            'code' => $promo->code,
            'discount_type' => $promo->discount_type,
            'discount_value' => $promo->discount_value,
            'discount_amount' => $discountAmount,
            'final_total' => $finalTotal,
        ], 'Promo berhasil digunakan');
    }
}
