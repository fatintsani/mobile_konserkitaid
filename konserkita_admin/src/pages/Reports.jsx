import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { RefreshCcw, Download, DollarSign, Ticket } from 'lucide-react';

const Reports = () => {
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchReport = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/reports/sales');
      if (response.data.success) {
        setReport(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch reports', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReport();
  }, []);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount);
  };

  const exportCSV = () => {
    if (!report?.revenue_per_event) return;
    
    const headers = ['Event ID', 'Event Title', 'Tickets Sold', 'Revenue'];
    const rows = report.revenue_per_event.map(item => [
      item.id,
      `"${item.title.replace(/"/g, '""')}"`,
      item.tickets_sold,
      item.revenue
    ]);
    
    const csvContent = [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', 'sales_report.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Sales Reports</h1>
        <div className="flex space-x-3">
          <button 
            onClick={exportCSV}
            disabled={!report?.revenue_per_event?.length}
            className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg shadow-sm hover:bg-[#5b24b8] disabled:opacity-50"
          >
            <Download size={18} className="mr-2" />
            Export CSV
          </button>
          <button onClick={fetchReport} className="p-2 text-gray-500 hover:text-[#6C2BD9] bg-white rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
        </div>
      </div>

      {loading ? (
        <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
      ) : (
        <>
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 flex items-center space-x-4">
            <div className="p-4 rounded-full bg-emerald-50 text-emerald-500">
              <DollarSign size={32} />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">Total Platform Revenue (Success)</p>
              <h3 className="text-3xl font-bold text-gray-800">{formatCurrency(report?.total_revenue || 0)}</h3>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100">
              <h2 className="text-lg font-bold text-gray-800">Revenue per Event</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Event ID</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Tickets Sold</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Revenue</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {!report?.revenue_per_event || report.revenue_per_event.length === 0 ? (
                    <tr>
                      <td colSpan="4" className="px-6 py-8 text-center text-gray-500">No sales data available.</td>
                    </tr>
                  ) : (
                    report.revenue_per_event.map((item) => (
                      <tr key={item.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">#{item.id}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{item.title}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-900">
                          <span className="flex items-center justify-end">
                            <Ticket size={14} className="mr-1 text-gray-400" />
                            {item.tickets_sold}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium text-emerald-600">
                          {formatCurrency(item.revenue)}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default Reports;
