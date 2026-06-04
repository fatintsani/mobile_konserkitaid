<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AdminBannerController extends BaseController
{
    public function index()
    {
        $banners = Banner::orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($banners, 'Banners retrieved successfully.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image' => 'required|image|max:2048',
            'link_url' => 'nullable|string|max:255',
            'status' => 'required|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('banners', 'public');
            $validated['image_url'] = url('storage/' . $path);
        }

        $banner = Banner::create($validated);
        return $this->sendResponse($banner, 'Banner created successfully.');
    }

    public function update(Request $request, $id)
    {
        $banner = Banner::find($id);
        if (!$banner) {
            return $this->sendError('Banner not found', [], 404);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image' => 'nullable|image|max:2048',
            'link_url' => 'nullable|string|max:255',
            'status' => 'required|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($request->hasFile('image')) {
            if ($banner->image_url) {
                $oldPath = str_replace(url('storage') . '/', '', $banner->image_url);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('image')->store('banners', 'public');
            $validated['image_url'] = url('storage/' . $path);
        }

        $banner->update($validated);
        return $this->sendResponse($banner, 'Banner updated successfully.');
    }

    public function destroy($id)
    {
        $banner = Banner::find($id);
        if (!$banner) {
            return $this->sendError('Banner not found', [], 404);
        }

        if ($banner->image_url) {
            $oldPath = str_replace(url('storage') . '/', '', $banner->image_url);
            Storage::disk('public')->delete($oldPath);
        }

        $banner->delete();
        return $this->sendResponse([], 'Banner deleted successfully.');
    }
}
