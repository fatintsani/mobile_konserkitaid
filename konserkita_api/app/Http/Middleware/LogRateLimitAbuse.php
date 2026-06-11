<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use App\Models\ApiAbuseLog;

class LogRateLimitAbuse extends ThrottleRequests
{
    protected function handleRequestUsingNamedLimiter($request, Closure $next, $limiterName, Closure $limiter)
    {
        try {
            return parent::handleRequestUsingNamedLimiter($request, $next, $limiterName, $limiter);
        } catch (ThrottleRequestsException $e) {
            $this->logAbuse($request, $limiterName);
            throw $e;
        }
    }

    protected function handleRequest($request, Closure $next, array $limits)
    {
        try {
            return parent::handleRequest($request, $next, $limits);
        } catch (ThrottleRequestsException $e) {
            $this->logAbuse($request, 'default');
            throw $e;
        }
    }

    protected function logAbuse($request, $limiterName)
    {
        ApiAbuseLog::create([
            'user_id' => $request->user()?->id,
            'ip_address' => $request->ip(),
            'endpoint' => $request->path(),
            'method' => $request->method(),
            'limiter' => $limiterName,
            'user_agent' => $request->userAgent(),
        ]);
    }
}
