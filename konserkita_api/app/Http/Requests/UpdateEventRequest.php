<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|required|string',
            'category_id' => 'sometimes|required|exists:event_categories,id',
            'date' => 'sometimes|required|date',
            'time' => 'sometimes|required|date_format:H:i',
            'location' => 'sometimes|required|string|max:255',
            'banner_image' => 'nullable|url',
            'status' => 'sometimes|required|string|in:draft,pending,published,cancelled,completed',
        ];
    }
}
