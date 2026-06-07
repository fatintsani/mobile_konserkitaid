<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ReviewModeratedNotification extends Notification
{
    use Queueable;

    /**
     * Create a new notification instance.
     */
    private $review;

    public function __construct($review)
    {
        $this->review = $review;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->line('The introduction to the notification.')
            ->action('Notification Action', url('/'))
            ->line('Thank you for using our application!');
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $statusStr = ucfirst($this->review->status);
        $message = "Your review for " . $this->review->event->title . " has been $statusStr.";
        if ($this->review->status === 'rejected' && $this->review->admin_note) {
            $message .= " Reason: " . $this->review->admin_note;
        }

        return [
            'title' => "Review $statusStr",
            'message' => $message,
            'type' => 'review',
            'reference_id' => $this->review->id,
        ];
    }
}
