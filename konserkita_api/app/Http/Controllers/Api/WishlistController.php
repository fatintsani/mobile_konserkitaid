<?php

namespace App\Http\Controllers\Api;

use App\Models\Wishlist;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class WishlistController extends BaseController
{
    public function index(Request $request)
    {
        $wishlists = Wishlist::with('event.category', 'event.organizer')
            ->where('user_id', $request->user()->id)
            ->get();
            
        return $this->sendResponse($wishlists, 'Wishlist retrieved successfully.');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'event_id' => 'required|exists:events,id',
        ]);

        if($validator->fails()){
            return $this->sendError('Validation Error.', $validator->errors(), 422);       
        }

        $wishlist = Wishlist::firstOrCreate([
            'user_id' => $request->user()->id,
            'event_id' => $request->event_id,
        ]);

        return $this->sendResponse($wishlist, 'Event added to wishlist.');
    }

    public function destroy(Request $request, $event_id)
    {
        $wishlist = Wishlist::where('event_id', $event_id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (is_null($wishlist)) {
            return $this->sendError('Wishlist item not found.');
        }

        $wishlist->delete();

        return $this->sendResponse([], 'Event removed from wishlist.');
    }
}
