<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\WishlistController;
use App\Http\Controllers\Api\ReferralController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\Admin\AdminController;
use App\Http\Controllers\Api\Admin\AdminReferralController;
use App\Http\Controllers\Api\Admin\AdminRecommendationController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/{provider}', [\App\Http\Controllers\Api\SocialAuthController::class, 'login']);

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/banners', [\App\Http\Controllers\Api\BannerController::class, 'index']);
Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);
Route::get('/events/{event}/seat-map', [\App\Http\Controllers\Api\EventSeatController::class, 'getSeatMap']);
Route::get('/events/{event}/reviews', [\App\Http\Controllers\Api\EventReviewController::class, 'index']);
Route::get('/events/{event}/rating-summary', [\App\Http\Controllers\Api\EventReviewController::class, 'ratingSummary']);
// Midtrans Webhook Notification
Route::post('/payments/midtrans/callback', [PaymentController::class, 'notificationHandler']);

// Referral Clicks (Public)
Route::post('/referrals/track-click', [\App\Http\Controllers\Api\ReferralController::class, 'trackClick']);

// Organizer Marketplace (Public)
Route::get('/organizers', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'index']);
Route::get('/organizers/{slug}', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'show']);
Route::get('/organizers/{slug}/events', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'events']);
Route::get('/organizers/{slug}/reviews', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'reviews']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Device Tokens
    Route::post('/device-tokens', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('/device-tokens', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);

    // Transactions
    Route::get('/transactions', [App\Http\Controllers\Api\TransactionController::class, 'index']);
    Route::get('/transactions/{id}', [App\Http\Controllers\Api\TransactionController::class, 'show']);

    // Payments
    Route::get('/payments/status/{id}', [PaymentController::class, 'status']);

    // Wishlist
    Route::get('/wishlists', [WishlistController::class, 'index']);
    Route::post('/wishlists', [WishlistController::class, 'store']);
    Route::delete('/wishlists/{id}', [WishlistController::class, 'destroy']);

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);

    // Organizer Dashboard
    Route::prefix('organizer')->middleware(\App\Http\Middleware\OrganizerMiddleware::class)->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Api\OrganizerController::class, 'dashboard']);
        Route::get('/events', [\App\Http\Controllers\Api\OrganizerController::class, 'events']);
        Route::post('/events', [\App\Http\Controllers\Api\OrganizerController::class, 'storeEvent']);
        Route::get('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'eventDetail']);
        Route::put('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'updateEvent']);
        Route::delete('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'destroyEvent']);
        Route::get('/events/{id}/sales', [\App\Http\Controllers\Api\OrganizerController::class, 'sales']);
        Route::get('/events/{id}/attendees', [\App\Http\Controllers\Api\OrganizerController::class, 'attendees']);
        Route::post('/events/{id}/ticket-types', [\App\Http\Controllers\Api\OrganizerController::class, 'storeTicketType']);
        Route::put('/ticket-types/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'updateTicketType']);
        Route::delete('/ticket-types/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'destroyTicketType']);
        
        // Payouts
        Route::get('/payouts/balance', [\App\Http\Controllers\Api\Organizer\PayoutController::class, 'balance']);
        Route::get('/payouts', [\App\Http\Controllers\Api\Organizer\PayoutController::class, 'index']);

        // Subscriptions
        Route::prefix('subscription')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Organizer\SubscriptionController::class, 'getSubscription']);
            Route::post('/upgrade', [\App\Http\Controllers\Api\Organizer\SubscriptionController::class, 'upgrade']);
            Route::post('/cancel', [\App\Http\Controllers\Api\Organizer\SubscriptionController::class, 'cancel']);
            Route::get('/payments', [\App\Http\Controllers\Api\Organizer\SubscriptionController::class, 'payments']);
        });
    });

    // Promo route
    Route::post('/promos/validate', [App\Http\Controllers\Api\PromoController::class, 'validateCode']);

    // Admin Dashboard
    Route::prefix('admin')->middleware(\App\Http\Middleware\AdminMiddleware::class)->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard']);
        
        Route::get('/events', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'index']);
        Route::get('/events/{id}', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'show']);
        Route::put('/events/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'approve']);
        Route::put('/events/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'reject']);
        Route::delete('/events/{id}', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'destroy']);
        
        Route::get('/users', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'index']);
        Route::get('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'show']);
        Route::put('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'update']);
        Route::delete('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'destroy']);
        
        Route::get('/organizers', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'index']);
        Route::get('/organizers/{id}', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'show']);
        Route::put('/organizers/{id}/verify', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'verify']);
        Route::put('/organizers/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'reject']);
        Route::put('/organizers/{id}/suspend', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'suspend']);
        Route::get('/organizer-reviews', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'reviews']);
        Route::put('/organizer-reviews/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'approveReview']);
        Route::put('/organizer-reviews/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'rejectReview']);

        // Admin Referrals
        Route::get('/referrals/stats', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'stats']);
        Route::get('/referrals/codes', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'codes']);
        Route::get('/referrals/conversions', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'conversions']);
        Route::get('/referrals/rewards', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'rewards']);
        Route::post('/referrals/rewards/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'approveReward']);
        Route::post('/referrals/rewards/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'rejectReward']);
        Route::post('/referrals/rewards/{id}/mark-paid', [\App\Http\Controllers\Api\Admin\AdminReferralController::class, 'markPaid']);
        
        Route::get('/transactions', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'index']);
        Route::get('/transactions/{id}', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'show']);
        
        Route::get('/reports/sales', [\App\Http\Controllers\Api\Admin\AdminReportController::class, 'sales']);

        // Refunds
        Route::get('/refunds', [\App\Http\Controllers\Api\Admin\AdminRefundController::class, 'index']);
        Route::get('/refunds/{id}', [\App\Http\Controllers\Api\Admin\AdminRefundController::class, 'show']);
        Route::put('/refunds/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminRefundController::class, 'approve']);
        Route::put('/refunds/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminRefundController::class, 'reject']);
        Route::put('/refunds/{id}/process', [\App\Http\Controllers\Api\Admin\AdminRefundController::class, 'process']);

        // Payouts
        Route::get('/payouts', [\App\Http\Controllers\Api\Admin\AdminPayoutController::class, 'index']);
        Route::get('/payouts/{id}', [\App\Http\Controllers\Api\Admin\AdminPayoutController::class, 'show']);
        Route::put('/payouts/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminPayoutController::class, 'approve']);
        Route::put('/payouts/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminPayoutController::class, 'reject']);
        Route::put('/payouts/{id}/mark-paid', [\App\Http\Controllers\Api\Admin\AdminPayoutController::class, 'markPaid']);

        // Referrals
        Route::get('/referrals/stats', [AdminReferralController::class, 'stats']);
        Route::get('/referrals/rewards', [AdminReferralController::class, 'rewards']);
        Route::get('/referrals/codes', [AdminReferralController::class, 'codes']);
        Route::get('/referrals/conversions', [AdminReferralController::class, 'conversions']);
        Route::post('/referrals/rewards/{reward}/approve', [AdminReferralController::class, 'approveReward']);
        Route::post('/referrals/rewards/{reward}/reject', [AdminReferralController::class, 'rejectReward']);
        Route::post('/referrals/rewards/{reward}/pay', [AdminReferralController::class, 'payReward']);

        // Recommendations
        Route::get('/recommendations/analytics', [AdminRecommendationController::class, 'analytics']);

        // Content Management
        Route::apiResource('banners', \App\Http\Controllers\Api\Admin\AdminBannerController::class);
        Route::apiResource('promos', \App\Http\Controllers\Api\Admin\AdminPromoController::class);
        Route::apiResource('event-categories', \App\Http\Controllers\Api\Admin\AdminCategoryController::class);

        // Venues & Seats
        Route::apiResource('venues', \App\Http\Controllers\Api\Admin\AdminVenueController::class);
        Route::post('/venues/{id}/sections', [\App\Http\Controllers\Api\Admin\AdminVenueController::class, 'storeSection']);
        Route::post('/sections/{id}/generate-seats', [\App\Http\Controllers\Api\Admin\AdminVenueController::class, 'generateSeats']);
        Route::post('/events/{id}/seat-map', [\App\Http\Controllers\Api\Admin\AdminVenueController::class, 'assignSeatMap']);

        // Reviews
        Route::get('/reviews', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'index']);
        Route::put('/reviews/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'approve']);
        Route::put('/reviews/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'reject']);
        Route::delete('/reviews/{id}', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'destroy']);

        // Notifications
        Route::post('/notifications/broadcast', [\App\Http\Controllers\Api\Admin\AdminNotificationController::class, 'broadcast']);

        // SaaS Subscriptions
        Route::prefix('subscription-plans')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'getPlans']);
            Route::post('/', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'createPlan']);
            Route::put('/{id}', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'updatePlan']);
            Route::delete('/{id}', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'deletePlan']);
        });

        Route::prefix('subscriptions')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'getSubscriptions']);
            Route::get('/{id}', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'getSubscription']);
        });
    });

    // Subscription Plans (Read-only for organizer/public)
    Route::get('/subscription-plans', [\App\Http\Controllers\Api\Admin\AdminSubscriptionController::class, 'getPlans']);

    Route::get('/event-categories', [\App\Http\Controllers\Api\OrganizerController::class, 'getCategories']);

    // Checkout
    Route::post('/checkout', [CheckoutController::class, 'process']);
    Route::post('/events/{event}/seats/hold', [\App\Http\Controllers\Api\EventSeatController::class, 'holdSeats']);
    Route::post('/events/{event}/seats/release', [\App\Http\Controllers\Api\EventSeatController::class, 'releaseSeats']);

    // Referrals (Customer)
    Route::get('/referrals/my-code', [\App\Http\Controllers\Api\ReferralController::class, 'myCode']);
    Route::get('/referrals/rewards', [\App\Http\Controllers\Api\ReferralController::class, 'rewards']);
    Route::get('/referrals/conversions', [\App\Http\Controllers\Api\ReferralController::class, 'conversions']);
    Route::post('/referrals/apply', [\App\Http\Controllers\Api\ReferralController::class, 'apply']);

    // Tickets
    Route::post('/tickets/scan', [TicketController::class, 'scanTicket']);
    Route::get('/tickets', [TicketController::class, 'myTickets']);
    Route::get('/tickets/{ticket_code}', [TicketController::class, 'showQR']);

    // Recommendations & Interactions
    Route::get('/recommendations', [RecommendationController::class, 'getRecommendations']);
    Route::post('/interactions', [RecommendationController::class, 'recordInteraction']);
    Route::get('/preferences', [RecommendationController::class, 'getPreferences']);
    Route::put('/preferences', [RecommendationController::class, 'updatePreferences']);

    // Refunds
    Route::post('/refunds', [\App\Http\Controllers\Api\RefundController::class, 'store']);
    Route::get('/refunds', [\App\Http\Controllers\Api\RefundController::class, 'index']);
    Route::get('/refunds/{id}', [\App\Http\Controllers\Api\RefundController::class, 'show']);

    // Reviews
    Route::get('/my-reviews', [\App\Http\Controllers\Api\CustomerReviewController::class, 'myReviews']);
    Route::post('/events/{event}/reviews', [\App\Http\Controllers\Api\CustomerReviewController::class, 'store']);
    Route::put('/reviews/{id}', [\App\Http\Controllers\Api\CustomerReviewController::class, 'update']);
    Route::delete('/reviews/{id}', [\App\Http\Controllers\Api\CustomerReviewController::class, 'destroy']);

    // Organizer Follow & Reviews (Protected)
    Route::get('/organizers/following', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'following']);
    Route::post('/organizers/{id}/follow', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'follow']);
    Route::delete('/organizers/{id}/follow', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'unfollow']);
    Route::post('/organizers/{id}/reviews', [\App\Http\Controllers\Api\PublicOrganizerController::class, 'storeReview']);
});
