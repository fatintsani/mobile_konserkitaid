<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TwoFactorResetRequestedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct()
    {
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
                    ->subject('Two-Factor Authentication Reset Requested')
                    ->line('We received a request to disable Two-Factor Authentication on your account because you lost access.')
                    ->line('This request is currently under review by an administrator. Please allow up to 48 hours for the review process.')
                    ->line('If you did not request this, please contact our support team immediately to secure your account.')
                    ->action('Contact Support', url('/contact'));
    }
}
