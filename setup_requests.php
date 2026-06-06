<?php
$base = __DIR__ . '/konserkita_api/app/Http/Requests';

$requests = [
    'Auth/RegisterRequest.php' => [
        "'name' => 'required|string|max:255',",
        "'email' => 'required|string|email|max:255|unique:users',",
        "'password' => 'required|string|min:6|confirmed',",
        "'role' => 'nullable|in:customer,organizer',"
    ],
    'Auth/LoginRequest.php' => [
        "'email' => 'required|string|email',",
        "'password' => 'required|string',"
    ],
    'Auth/UpdateProfileRequest.php' => [
        "'name' => 'sometimes|string|max:255',",
        "'phone' => 'sometimes|string|max:20',"
    ],
    'Checkout/ProcessCheckoutRequest.php' => [
        "'event_id' => 'required|exists:events,id',",
        "'ticket_types' => 'required|array|min:1',",
        "'ticket_types.*.id' => 'required|exists:ticket_types,id',",
        "'ticket_types.*.quantity' => 'required|integer|min:1',",
        "'promo_code' => 'nullable|string|exists:promos,code',"
    ],
    'Promo/ValidatePromoRequest.php' => [
        "'promo_code' => 'required|string|exists:promos,code',",
        "'event_id' => 'required|exists:events,id',",
        "'total_amount' => 'required|numeric|min:0',"
    ],
    'Wishlist/StoreWishlistRequest.php' => [
        "'event_id' => 'required|exists:events,id',"
    ],
    'Ticket/ScanTicketRequest.php' => [
        "'ticket_code' => 'required|string|exists:tickets,ticket_code',"
    ],
];

foreach ($requests as $file => $rules) {
    $path = "$base/$file";
    if (file_exists($path)) {
        $content = file_get_contents($path);
        // change authorize to true
        $content = str_replace('return false;', 'return true;', $content);
        
        $rulesStr = implode("\n            ", $rules);
        $content = preg_replace('/public function rules\(\): array\s*\{\s*return \[\s*\];\s*\}/', "public function rules(): array\n    {\n        return [\n            $rulesStr\n        ];\n    }", $content);
        
        file_put_contents($path, $content);
        echo "Updated $file\n";
    }
}
