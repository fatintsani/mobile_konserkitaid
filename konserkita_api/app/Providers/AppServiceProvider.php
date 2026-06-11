<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('auth_login', function (Request $request) {
            return Limit::perMinute(5)->by($request->email ?: $request->ip());
        });

        RateLimiter::for('auth_2fa', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('passkey_challenge', function (Request $request) {
            return Limit::perMinute(10)->by($request->email ?: $request->ip());
        });

        RateLimiter::for('social_login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('checkout', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('payment_status', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('referral_apply', function (Request $request) {
            return Limit::perHour(10)->by(($request->user()?->id ?: '') . $request->ip());
        });

        RateLimiter::for('review_submit', function (Request $request) {
            return Limit::perHour(5)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('refund_request', function (Request $request) {
            return Limit::perHour(3)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('public_search', function (Request $request) {
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('admin_actions', function (Request $request) {
            return Limit::perMinute(120)->by($request->user()?->id ?: $request->ip());
        });
    }
}
