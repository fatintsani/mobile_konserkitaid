import React, { useState, useEffect } from "react";
import api from "../api/axios";
import { Search, Eye, Filter, ShieldAlert, CheckCircle, XCircle } from "lucide-react";
import toast from "react-hot-toast";

const AuditTrail = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [meta, setMeta] = useState(null);
  const [page, setPage] = useState(1);
  const [filters, setFilters] = useState({
    action: "",
    module: "",
    date_from: "",
    date_to: "",
    admin_id: "",
  });
  const [selectedLog, setSelectedLog] = useState(null);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const query = new URLSearchParams({ page, ...filters }).toString();
      const response = await api.get(`/admin/audit-logs?${query}`);
      setLogs(response.data.data.data);
      setMeta({
        current_page: response.data.data.current_page,
        last_page: response.data.data.last_page,
        total: response.data.data.total,
      });
    } catch (error) {
      toast.error("Gagal memuat audit logs.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [page]);

  const handleFilterChange = (e) => {
    setFilters({ ...filters, [e.target.name]: e.target.value });
  };

  const handleFilterSubmit = (e) => {
    e.preventDefault();
    setPage(1);
    fetchLogs();
  };

  const formatJSON = (data) => {
    if (!data) return "N/A";
    try {
      return JSON.stringify(data, null, 2);
    } catch (e) {
      return "Invalid JSON";
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white">Admin Audit Trail</h1>
      </div>

      <div className="bg-[#1e1e1e] p-6 rounded-xl border border-white/10">
        <form onSubmit={handleFilterSubmit} className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">Module</label>
            <input
              type="text"
              name="module"
              value={filters.module}
              onChange={handleFilterChange}
              placeholder="e.g. events, users"
              className="w-full bg-[#2a2a2a] text-white rounded-lg px-4 py-2 border border-white/10 focus:outline-none focus:border-[#4B9FFF]"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">Action</label>
            <input
              type="text"
              name="action"
              value={filters.action}
              onChange={handleFilterChange}
              placeholder="e.g. event_approved"
              className="w-full bg-[#2a2a2a] text-white rounded-lg px-4 py-2 border border-white/10 focus:outline-none focus:border-[#4B9FFF]"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">Date From</label>
            <input
              type="date"
              name="date_from"
              value={filters.date_from}
              onChange={handleFilterChange}
              className="w-full bg-[#2a2a2a] text-white rounded-lg px-4 py-2 border border-white/10 focus:outline-none focus:border-[#4B9FFF]"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">Date To</label>
            <input
              type="date"
              name="date_to"
              value={filters.date_to}
              onChange={handleFilterChange}
              className="w-full bg-[#2a2a2a] text-white rounded-lg px-4 py-2 border border-white/10 focus:outline-none focus:border-[#4B9FFF]"
            />
          </div>
          <div className="flex items-end">
            <button
              type="submit"
              className="w-full bg-[#4B9FFF] hover:bg-[#3b82f6] text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center justify-center gap-2"
            >
              <Filter className="w-5 h-5" /> Filter
            </button>
          </div>
        </form>
      </div>

      <div className="bg-[#1e1e1e] rounded-xl border border-white/10 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-white/80">
            <thead className="bg-[#2a2a2a] text-white/60 text-sm">
              <tr>
                <th className="px-6 py-4 font-medium">Timestamp</th>
                <th className="px-6 py-4 font-medium">Admin</th>
                <th className="px-6 py-4 font-medium">Action</th>
                <th className="px-6 py-4 font-medium">Module</th>
                <th className="px-6 py-4 font-medium">Description</th>
                <th className="px-6 py-4 font-medium">Target ID</th>
                <th className="px-6 py-4 font-medium text-right">Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/10">
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="animate-pulse border-b border-white/5">
                    <td colSpan="10" className="px-6 py-5">
                      <div className="flex space-x-4">
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                      </div>
                    </td>
                  </tr>
                ))
              ) :  logs.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-8 text-center text-white/60">
                    Tidak ada log audit ditemukan.
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-white/5">
                    <td className="px-6 py-4 text-sm">{new Date(log.created_at).toLocaleString('id-ID')}</td>
                    <td className="px-6 py-4 text-sm">
                      <div className="font-medium text-white">{log.admin?.name || 'Unknown'}</div>
                      <div className="text-xs text-white/50">{log.admin?.email}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-3 py-1 bg-white/10 text-white text-xs rounded-full">
                        {log.action}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm capitalize">{log.module}</td>
                    <td className="px-6 py-4 text-sm">{log.description || '-'}</td>
                    <td className="px-6 py-4 text-sm">{log.target_id || '-'}</td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="p-2 hover:bg-white/10 rounded-lg transition-colors text-white/60 hover:text-white"
                        title="View Details"
                      >
                        <Eye className="w-5 h-5" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && meta && meta.last_page > 1 && (
          <div className="p-4 border-t border-white/10 flex items-center justify-between">
            <span className="text-sm text-white/60">
              Halaman {meta.current_page} dari {meta.last_page}
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1 bg-[#2a2a2a] text-white rounded-lg disabled:opacity-50"
              >
                Prev
              </button>
              <button
                onClick={() => setPage((p) => Math.min(meta.last_page, p + 1))}
                disabled={page === meta.last_page}
                className="px-3 py-1 bg-[#2a2a2a] text-white rounded-lg disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {selectedLog && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1e1e1e] rounded-2xl w-full max-w-4xl max-h-[90vh] overflow-y-auto border border-white/10 shadow-2xl p-6">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h2 className="text-2xl font-bold text-white mb-2">Audit Log Detail</h2>
                <p className="text-white/60 text-sm">Log ID: #{selectedLog.id}</p>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-white/60 hover:text-white p-2 rounded-lg hover:bg-white/10"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-6 mb-8">
              <div className="bg-[#2a2a2a] p-4 rounded-xl border border-white/5">
                <h3 className="text-sm font-semibold text-white/40 uppercase mb-4">Context</h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-white/60">Admin</span>
                    <span className="text-white">{selectedLog.admin?.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">Action</span>
                    <span className="text-white font-mono">{selectedLog.action}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">Module</span>
                    <span className="text-white font-mono">{selectedLog.module}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">Timestamp</span>
                    <span className="text-white">{new Date(selectedLog.created_at).toLocaleString('id-ID')}</span>
                  </div>
                </div>
              </div>

              <div className="bg-[#2a2a2a] p-4 rounded-xl border border-white/5">
                <h3 className="text-sm font-semibold text-white/40 uppercase mb-4">Network & Target</h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-white/60">IP Address</span>
                    <span className="text-white">{selectedLog.ip_address || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">User Agent</span>
                    <span className="text-white truncate max-w-[200px]" title={selectedLog.user_agent}>
                      {selectedLog.user_agent || '-'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">Target Type</span>
                    <span className="text-white truncate max-w-[200px]">{selectedLog.target_type || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-white/60">Target ID</span>
                    <span className="text-white">{selectedLog.target_id || '-'}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 className="text-sm font-semibold text-white mb-2">Old Values</h3>
                <div className="bg-[#0d0d0d] rounded-xl p-4 overflow-x-auto border border-white/10">
                  <pre className="text-[#4B9FFF] text-xs font-mono">
                    {formatJSON(selectedLog.old_values)}
                  </pre>
                </div>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white mb-2">New Values</h3>
                <div className="bg-[#0d0d0d] rounded-xl p-4 overflow-x-auto border border-white/10">
                  <pre className="text-green-400 text-xs font-mono">
                    {formatJSON(selectedLog.new_values)}
                  </pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AuditTrail;
