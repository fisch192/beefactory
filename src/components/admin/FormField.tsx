import { h } from 'preact';

interface FormFieldProps {
  label: string;
  type?: string;
  value: any;
  onChange: (v: any) => void;
  required?: boolean;
  placeholder?: string;
  rows?: number;
  min?: number;
  max?: number;
  step?: number;
  disabled?: boolean;
}

export default function FormField({
  label,
  type = 'text',
  value,
  onChange,
  required = false,
  placeholder = '',
  rows,
  min,
  max,
  step,
  disabled = false,
}: FormFieldProps) {
  const baseClasses =
    'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-[#0f0f0f] ' +
    'placeholder:text-gray-400 focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 ' +
    'focus:outline-none transition-colors disabled:bg-gray-100 disabled:text-gray-500';

  if (type === 'checkbox') {
    return (
      <label class="flex items-center gap-2 cursor-pointer select-none">
        <input
          type="checkbox"
          checked={!!value}
          onChange={(e) => onChange((e.target as HTMLInputElement).checked)}
          class="h-4 w-4 rounded border-gray-300 text-[#D4A843] focus:ring-[#D4A843]/20"
          disabled={disabled}
        />
        <span class="text-sm font-medium text-[#0f0f0f]">{label}</span>
        {required && <span class="text-red-500">*</span>}
      </label>
    );
  }

  return (
    <div class="space-y-1">
      <label class="block text-sm font-medium text-[#0f0f0f]">
        {label}
        {required && <span class="text-red-500 ml-0.5">*</span>}
      </label>
      {type === 'textarea' || rows ? (
        <textarea
          class={baseClasses}
          value={value ?? ''}
          onInput={(e) => onChange((e.target as HTMLTextAreaElement).value)}
          required={required}
          placeholder={placeholder}
          rows={rows ?? 4}
          disabled={disabled}
        />
      ) : type === 'number' ? (
        <input
          type="number"
          class={baseClasses}
          value={value ?? ''}
          onInput={(e) => {
            const v = (e.target as HTMLInputElement).value;
            onChange(v === '' ? '' : Number(v));
          }}
          required={required}
          placeholder={placeholder}
          min={min}
          max={max}
          step={step}
          disabled={disabled}
        />
      ) : (
        <input
          type={type}
          class={baseClasses}
          value={value ?? ''}
          onInput={(e) => onChange((e.target as HTMLInputElement).value)}
          required={required}
          placeholder={placeholder}
          disabled={disabled}
        />
      )}
    </div>
  );
}
