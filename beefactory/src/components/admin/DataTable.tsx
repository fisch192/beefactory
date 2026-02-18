import { h } from 'preact';

interface Column {
  key: string;
  label: string;
  render?: (value: any, row: any) => any;
}

interface DataTableProps {
  columns: Column[];
  data: any[];
  actions?: (row: any) => any;
  emptyMessage?: string;
}

export default function DataTable({ columns, data, actions, emptyMessage = 'Keine Eintraege vorhanden.' }: DataTableProps) {
  if (!data || data.length === 0) {
    return (
      <div class="text-center py-12 text-gray-500">
        <p>{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div class="overflow-x-auto rounded-lg border border-gray-200">
      <table class="w-full text-sm">
        <thead>
          <tr class="bg-gray-50 border-b border-gray-200">
            {columns.map((col) => (
              <th
                key={col.key}
                class="text-left px-4 py-3 font-semibold text-[#0f0f0f] whitespace-nowrap"
              >
                {col.label}
              </th>
            ))}
            {actions && (
              <th class="text-right px-4 py-3 font-semibold text-[#0f0f0f]">Aktionen</th>
            )}
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          {data.map((row, i) => (
            <tr key={row.id || row.handle || i} class="hover:bg-gray-50/50 transition-colors">
              {columns.map((col) => (
                <td key={col.key} class="px-4 py-3 text-gray-700">
                  {col.render ? col.render(row[col.key], row) : (row[col.key] ?? '—')}
                </td>
              ))}
              {actions && (
                <td class="px-4 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    {actions(row)}
                  </div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
