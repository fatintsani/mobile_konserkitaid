import React, { useState, useEffect } from "react";
import api from "../api/axios";
import { BarChart, Users, Star, Activity, MapPin } from "lucide-react";

export default function Recommendations() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
      const response = await api.get("/admin/recommendations/analytics");
      setData(response.data.data);
    } catch (error) {
      console.error("Failed to fetch analytics", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!data) return <div className="p-6">No data available</div>;

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Recommendation Analytics</h1>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard title="Total Recommendations" value={data.total_recommendations} icon={<Star className="text-yellow-500" />} />
        <StatCard title="Total Interactions" value={data.total_interactions} icon={<Activity className="text-blue-500" />} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <h2 className="text-lg font-semibold mb-4 flex items-center">
            <BarChart className="w-5 h-5 mr-2 text-indigo-500" />
            Top Categories
          </h2>
          <div className="space-y-4">
            {Object.entries(data.top_categories).map(([category, count]) => (
              <div key={category} className="flex justify-between items-center border-b pb-2">
                <span className="text-gray-700">{category}</span>
                <span className="font-semibold">{count}</span>
              </div>
            ))}
            {Object.keys(data.top_categories).length === 0 && <span className="text-gray-500 text-sm">No data</span>}
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100">
          <h2 className="text-lg font-semibold mb-4 flex items-center">
            <MapPin className="w-5 h-5 mr-2 text-red-500" />
            Top Locations
          </h2>
          <div className="space-y-4">
            {Object.entries(data.top_locations).map(([location, count]) => (
              <div key={location} className="flex justify-between items-center border-b pb-2">
                <span className="text-gray-700">{location}</span>
                <span className="font-semibold">{count}</span>
              </div>
            ))}
            {Object.keys(data.top_locations).length === 0 && <span className="text-gray-500 text-sm">No data</span>}
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100 lg:col-span-2">
          <h2 className="text-lg font-semibold mb-4 flex items-center">
            <Activity className="w-5 h-5 mr-2 text-green-500" />
            Interactions Summary
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {Object.entries(data.interaction_stats).map(([type, count]) => (
              <div key={type} className="bg-gray-50 p-4 rounded text-center">
                <span className="block text-sm text-gray-500 uppercase">{type}</span>
                <span className="block text-2xl font-bold mt-1">{count}</span>
              </div>
            ))}
            {Object.keys(data.interaction_stats).length === 0 && <span className="text-gray-500 text-sm">No data</span>}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, icon }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-100 flex items-center">
      <div className="p-3 rounded-full bg-gray-50 mr-4">
        {icon}
      </div>
      <div>
        <p className="text-sm text-gray-500 mb-1">{title}</p>
        <p className="text-2xl font-bold">{value}</p>
      </div>
    </div>
  );
}
