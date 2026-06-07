<?php

namespace App\Http\Controllers\Api;

use App\Models\Organizer;
use App\Models\OrganizerReview;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PublicOrganizerController extends BaseController
{
    public function index(Request $request)
    {
        $query = Organizer::where('status', 'verified')->withCount('followers');
        
        if ($request->has('popular')) {
            $query->orderBy('total_followers', 'desc')->orderBy('rating_average', 'desc');
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $organizers = $query->paginate(15);
        return $this->sendResponse($organizers, 'Organizers retrieved successfully.');
    }

    public function show($slug)
    {
        $organizer = Organizer::where('slug', $slug)
            ->withCount('followers')
            ->first();

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        if ($organizer->status !== 'verified' && $organizer->status !== 'pending') {
            return $this->sendError('Organizer profile is currently unavailable.', [], 403);
        }

        $isFollowed = false;
        if (Auth::guard('sanctum')->check()) {
            $userId = Auth::guard('sanctum')->id();
            $isFollowed = $organizer->followers()->where('user_id', $userId)->exists();
        }

        $organizer->is_followed = $isFollowed;

        return $this->sendResponse($organizer, 'Organizer profile retrieved successfully.');
    }

    public function events($slug)
    {
        $organizer = Organizer::where('slug', $slug)->first();
        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $events = $organizer->events()
            ->where('status', 'published')
            ->orderBy('date', 'desc')
            ->paginate(10);

        return $this->sendResponse($events, 'Organizer events retrieved successfully.');
    }

    public function reviews($slug)
    {
        $organizer = Organizer::where('slug', $slug)->first();
        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $reviews = $organizer->reviews()
            ->with('user:id,name,avatar')
            ->where('status', 'approved')
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return $this->sendResponse($reviews, 'Organizer reviews retrieved successfully.');
    }

    public function follow(Request $request, $id)
    {
        $organizer = Organizer::find($id);
        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $user = Auth::user();
        $isFollowing = $user->followedOrganizers()->where('organizer_id', $id)->exists();

        if (!$isFollowing) {
            $user->followedOrganizers()->attach($id);
            $organizer->increment('total_followers');

            \App\Models\Notification::create([
                'user_id' => $organizer->user_id,
                'title' => 'New Follower',
                'message' => $user->name . ' has started following you.',
                'type' => 'user_followed_organizer',
            ]);
        }

        return $this->sendResponse(null, 'Organizer followed successfully.');
    }

    public function unfollow(Request $request, $id)
    {
        $organizer = Organizer::find($id);
        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $user = Auth::user();
        $isFollowing = $user->followedOrganizers()->where('organizer_id', $id)->exists();

        if ($isFollowing) {
            $user->followedOrganizers()->detach($id);
            $organizer->decrement('total_followers');
        }

        return $this->sendResponse(null, 'Organizer unfollowed successfully.');
    }

    public function storeReview(Request $request, $id)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
        ]);

        $organizer = Organizer::find($id);
        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $user = Auth::user();

        // Validate if user has purchased from this organizer
        $hasPurchased = Transaction::where('user_id', $user->id)
            ->where('status', 'success')
            ->whereHas('event', function ($q) use ($id) {
                $q->where('organizer_id', $id);
            })->exists();

        if (!$hasPurchased) {
            return $this->sendError('You can only review organizers you have purchased tickets from.', [], 403);
        }

        // Check if already reviewed
        $existingReview = OrganizerReview::where('organizer_id', $id)->where('user_id', $user->id)->first();
        if ($existingReview) {
            return $this->sendError('You have already submitted a review for this organizer.', [], 400);
        }

        $review = OrganizerReview::create([
            'organizer_id' => $id,
            'user_id' => $user->id,
            'rating' => $request->rating,
            'comment' => $request->comment,
            'status' => 'pending',
        ]);

        return $this->sendResponse($review, 'Review submitted successfully and is pending approval.');
    }

    public function following(Request $request)
    {
        $user = Auth::user();
        $organizers = $user->followedOrganizers()->withCount('followers')->paginate(10);
        return $this->sendResponse($organizers, 'Followed organizers retrieved successfully.');
    }
}
