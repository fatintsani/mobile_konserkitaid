<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\EventCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use App\Services\AdminAuditService;

class AdminCategoryController extends BaseController
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
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

        $this->auditService->log(
            auth()->user(),
            'category_created',
            'event_categories',
            $category,
            null,
            $category->toArray(),
            "Created category: {$category->name}"
        );

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

        $oldValues = $category->toArray();
        $category->update($validated);

        $this->auditService->log(
            auth()->user(),
            'category_updated',
            'event_categories',
            $category,
            $oldValues,
            $category->toArray(),
            "Updated category: {$category->name}"
        );

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

        $oldValues = $category->toArray();
        $category->delete();

        $this->auditService->log(
            auth()->user(),
            'category_deleted',
            'event_categories',
            $category,
            $oldValues,
            null,
            "Deleted category: {$category->name}"
        );

        return $this->sendResponse([], 'Category deleted successfully.');
    }
}
