import React from 'react';
import { SearchType, SearchResultItem } from '@/types';
import { FiMapPin, FiUser, FiClock, FiDollarSign, FiHash } from 'react-icons/fi';
import { format } from 'date-fns';

interface ResultItemProps {
  item: SearchResultItem;
  collectionType: SearchType;
}

export default function ResultItem({ item, collectionType }: ResultItemProps) {
  const renderHighlight = (text: string) => {
    return <span dangerouslySetInnerHTML={{ __html: text }} />;
  };

  const getHighlightedField = (fieldName: string, defaultValue: string) => {
    if (item.search_highlights && item.search_highlights[fieldName]) {
      return renderHighlight(item.search_highlights[fieldName]);
    }
    return defaultValue;
  };

  const renderOrderItem = () => {
    const order = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('order_number', order.order_number)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                order.status === 'delivered' ? 'bg-green-100 text-green-800' :
                order.status === 'in_transit' ? 'bg-blue-100 text-blue-800' :
                order.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {order.status}
              </span>
              <span className="text-sm text-gray-400">
                Score: {order.search_score.toFixed(2)}
              </span>
            </div>

            {order.hawb_numbers && order.hawb_numbers.length > 0 && (
              <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                <FiHash className="w-4 h-4" />
                <span>HAWB: {order.hawb_numbers.join(', ')}</span>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4 mt-3">
              <div className="flex items-start gap-2">
                <FiMapPin className="w-4 h-4 text-gray-400 mt-1" />
                <div className="text-sm">
                  <div className="font-medium text-gray-700">Origin</div>
                  <div className="text-gray-600">
                    {order.origin?.city}, {order.origin?.state}
                  </div>
                </div>
              </div>

              <div className="flex items-start gap-2">
                <FiMapPin className="w-4 h-4 text-gray-400 mt-1" />
                <div className="text-sm">
                  <div className="font-medium text-gray-700">Destination</div>
                  <div className="text-gray-600">
                    {order.destination?.city}, {order.destination?.state}
                  </div>
                </div>
              </div>
            </div>

            {order.account && (
              <div className="mt-3 flex items-center gap-2 text-sm text-gray-600">
                <FiUser className="w-4 h-4" />
                <span>{order.account.account_name}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

  const renderAccountItem = () => {
    const account = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('account_name', account.account_name)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                account.status === 'active' ? 'bg-green-100 text-green-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {account.status}
              </span>
            </div>

            <div className="text-sm text-gray-600 mb-2">
              {account.account_number} • {account.account_type}
            </div>

            {account.company_name && (
              <div className="text-sm text-gray-700 mb-2">
                {account.company_name}
              </div>
            )}

            <div className="flex items-center gap-4 text-sm text-gray-600">
              {account.contact_person && <span>{account.contact_person}</span>}
              {account.email && <span>{account.email}</span>}
              {account.phone && <span>{account.phone}</span>}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderFleetItem = () => {
    const fleet = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('vehicle_name', fleet.vehicle_name || fleet.display_name)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                fleet.status === 'active' ? 'bg-green-100 text-green-800' :
                fleet.status === 'maintenance' ? 'bg-yellow-100 text-yellow-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {fleet.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-4 text-sm text-gray-600">
              <div>
                <span className="font-medium">VIN:</span> {fleet.vin}
              </div>
              <div>
                <span className="font-medium">License:</span> {fleet.license_plate}
              </div>
              <div>
                <span className="font-medium">Type:</span> {fleet.vehicle_type}
              </div>
            </div>

            <div className="mt-2 text-sm text-gray-700">
              {fleet.year} {fleet.make} {fleet.model}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderDriverItem = () => {
    const driver = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('full_name', driver.full_name)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                driver.status === 'active' ? 'bg-green-100 text-green-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {driver.status}
              </span>
            </div>

            <div className="text-sm text-gray-600 mb-2">
              ID: {driver.driver_id}
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-600">
              {driver.license_number && <span>License: {driver.license_number}</span>}
              {driver.email && <span>{driver.email}</span>}
              {driver.phone && <span>{driver.phone}</span>}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderBillingItem = () => {
    const billing = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('billing_number', billing.billing_number)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                billing.status === 'paid' ? 'bg-green-100 text-green-800' :
                billing.status === 'overdue' ? 'bg-red-100 text-red-800' :
                billing.status === 'sent' ? 'bg-blue-100 text-blue-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {billing.status}
              </span>
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
              <div className="flex items-center gap-1">
                <FiDollarSign className="w-4 h-4" />
                <span className="font-semibold">${billing.total_amount.toFixed(2)}</span>
              </div>
              {billing.billing_date && (
                <div className="flex items-center gap-1">
                  <FiClock className="w-4 h-4" />
                  <span>{format(new Date(billing.billing_date), 'MMM dd, yyyy')}</span>
                </div>
              )}
            </div>

            {billing.account && (
              <div className="text-sm text-gray-700">
                {billing.account.account_name}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

  const renderInvoiceItem = () => {
    const invoice = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('invoice_number', invoice.invoice_number)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                invoice.status === 'paid' ? 'bg-green-100 text-green-800' :
                invoice.status === 'sent' ? 'bg-blue-100 text-blue-800' :
                invoice.status === 'void' ? 'bg-red-100 text-red-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {invoice.status}
              </span>
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
              <div className="flex items-center gap-1">
                <FiDollarSign className="w-4 h-4" />
                <span className="font-semibold">${invoice.total_amount.toFixed(2)}</span>
              </div>
              {invoice.invoice_date && (
                <div className="flex items-center gap-1">
                  <FiClock className="w-4 h-4" />
                  <span>{format(new Date(invoice.invoice_date), 'MMM dd, yyyy')}</span>
                </div>
              )}
            </div>

            {invoice.account && (
              <div className="text-sm text-gray-700">
                {invoice.account.account_name}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

  const renderPodItem = () => {
    const pod = item as any;
    return (
      <div className="p-6 hover:bg-gray-50 transition-colors">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-2">
              <h4 className="text-lg font-semibold text-gray-900">
                {getHighlightedField('pod_number', pod.pod_number)}
              </h4>
              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                pod.delivery_status === 'completed' ? 'bg-green-100 text-green-800' :
                pod.delivery_status === 'failed' ? 'bg-red-100 text-red-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {pod.delivery_status}
              </span>
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-600">
              {pod.recipient_name && (
                <div className="flex items-center gap-1">
                  <FiUser className="w-4 h-4" />
                  <span>{pod.recipient_name}</span>
                </div>
              )}
              {pod.delivery_date && (
                <div className="flex items-center gap-1">
                  <FiClock className="w-4 h-4" />
                  <span>{format(new Date(pod.delivery_date), 'MMM dd, yyyy')}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  switch (collectionType) {
    case 'orders':
      return renderOrderItem();
    case 'accounts':
      return renderAccountItem();
    case 'fleets':
      return renderFleetItem();
    case 'drivers':
      return renderDriverItem();
    case 'billings':
      return renderBillingItem();
    case 'invoices':
      return renderInvoiceItem();
    case 'pods':
      return renderPodItem();
    default:
      return null;
  }
}
