<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class SensitiveActionConfirmedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $actionName;

    public function __construct($actionName)
    {
        $this->actionName = $actionName;
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
                    ->subject('Security Alert: Sensitive Action Performed')
                    ->line('A sensitive action was just performed on your account.')
                    ->line('Action: ' . $this->actionName)
                    ->line('If you did not authorize this action, please secure your account immediately.')
                    ->action('Review Security Settings', url('/profile/security'));
    }
}
