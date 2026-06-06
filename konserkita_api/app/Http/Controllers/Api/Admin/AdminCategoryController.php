<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\EventCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class AdminCategoryController extends BaseController
{
    public function index()
    {
        $categories = EventCategory::orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($categories, 'Categories retrieved successfully.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'icon' => 'nullable|image|max:2048',
            'description' => 'nullable|string',
            'status' => 'required|in:active,inactive',
        ]);

        $validated['slug'] = Str::slug($validated['name']);
        
        if ($request->hasFile('icon')) {
            $path = $request->file('icon')->store('categories', 'public');
            $validated['icon'] = url('storage/' . $path);
        }

        $category = EventCategory::create($validated);
        return $this->sendResponse($category, 'Category created successfully.');
    }

    public function update(Request $request, $id)
    {
        $category = EventCategory::find($id);
        if (!$category) {
            return $this->sendError('Category not found', [], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'icon' => 'nullable|image|max:2048',
            'description' => 'nullable|string',
            'status' => 'required|in:active,inactive',
        ]);

        $validated['slug'] = Str::slug($validated['name']);

        if ($request->hasFile('icon')) {
            if ($category->icon) {
                $oldPath = str_replace(url('storage') . '/', '', $category->icon);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('icon')->store('categories', 'public');
            $validated['icon'] = url('storage/' . $path);
        }

        $category->update($validated);
        return $this->sendResponse($category, 'Category updated successfully.');
    }

    public function destroy($id)
    {
        $category = EventCategory::find($id);
        if (!$category) {
            return $this->sendError('Category not found', [], 404);
        }

        if ($category->events()->exists()) {
            return $this->sendError('Cannot delete category because it is being used by events.', [], 400);
        }

        if ($category->icon) {
            $oldPath = str_replace(url('storage') . '/', '', $category->icon);
            Storage::disk('public')->delete($oldPath);
        }

        $category->delete();
        return $this->sendResponse([], 'Category deleted successfully.');
    }
}
