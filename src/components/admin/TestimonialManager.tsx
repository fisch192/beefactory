import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { getTestimonials, createTestimonial, updateTestimonial, deleteTestimonial } from '../../lib/admin-api';
import DataTable from './DataTable';
import Modal from './Modal';
import TestimonialForm from './TestimonialForm';

export default function TestimonialManager() {
  const [testimonials, setTestimonials] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editTestimonial, setEditTestimonial] = useState<any | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await getTestimonials();
      setTestimonials(data);
    } catch (err: any) {
      setError('Bewertungen konnten nicht geladen werden: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    try {
      if (editTestimonial) {
        await updateTestimonial(editTestimonial.id, data);
      } else {
        await createTestimonial(data);
      }
      setShowForm(false);
      setEditTestimonial(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Speichern: ' + err.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteTestimonial(deleteTarget.id);
      setDeleteTarget(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Loeschen: ' + err.message);
    }
  };

  const openEdit = (testimonial: any) => {
    setEditTestimonial(testimonial);
    setShowForm(true);
  };

  const openCreate = () => {
    setEditTestimonial(null);
    setShowForm(true);
  };

  const renderStars = (rating: number) => {
    return (
      <span class="text-[#D4A843]">
        {'★'.repeat(rating)}
        <span class="text-gray-300">{'★'.repeat(5 - rating)}</span>
      </span>
    );
  };

  const columns = [
    {
      key: 'name',
      label: 'Name',
    },
    {
      key: 'location',
      label: 'Ort',
      render: (v: any, row: any) => v || row.ort || '—',
    },
    {
      key: 'rating',
      label: 'Bewertung',
      render: (v: any) => renderStars(v ?? 0),
    },
    {
      key: 'text',
      label: 'Text',
      render: (_: any, row: any) => {
        const text = row.text?.de || row.textDe || '';
        return text.length > 60 ? text.substring(0, 60) + '...' : text || '—';
      },
    },
  ];

  return (
    <div class="max-w-5xl">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-[#0f0f0f]">Bewertungen</h1>
        <button
          onClick={openCreate}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-5 rounded-lg transition-colors text-sm"
        >
          + Neue Bewertung
        </button>
      </div>

      {error && (
        <div class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200 mb-4">
          {error}
        </div>
      )}

      {loading ? (
        <div class="text-center py-12 text-gray-500">Wird geladen...</div>
      ) : (
        <DataTable
          columns={columns}
          data={testimonials}
          emptyMessage="Noch keine Bewertungen vorhanden."
          actions={(row) => (
            <>
              <button
                onClick={() => openEdit(row)}
                class="text-sm text-[#D4A843] hover:text-[#c49a3a] font-medium"
              >
                Bearbeiten
              </button>
              <button
                onClick={() => setDeleteTarget(row)}
                class="text-sm text-red-500 hover:text-red-700 font-medium"
              >
                Loeschen
              </button>
            </>
          )}
        />
      )}

      {/* Testimonial Form Modal */}
      <Modal
        open={showForm}
        title={editTestimonial ? 'Bewertung bearbeiten' : 'Neue Bewertung'}
        onClose={() => {
          setShowForm(false);
          setEditTestimonial(null);
        }}
      >
        <TestimonialForm
          testimonial={editTestimonial}
          onSave={handleSave}
          onCancel={() => {
            setShowForm(false);
            setEditTestimonial(null);
          }}
        />
      </Modal>

      {/* Delete Confirmation */}
      <Modal
        open={!!deleteTarget}
        title="Bewertung loeschen"
        onClose={() => setDeleteTarget(null)}
      >
        <p class="text-sm text-gray-600 mb-6">
          Moechten Sie die Bewertung von <strong>{deleteTarget?.name}</strong> wirklich loeschen? Diese Aktion kann nicht rueckgaengig gemacht werden.
        </p>
        <div class="flex items-center justify-end gap-3">
          <button
            onClick={() => setDeleteTarget(null)}
            class="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
          >
            Abbrechen
          </button>
          <button
            onClick={handleDelete}
            class="bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-5 rounded-lg transition-colors text-sm"
          >
            Loeschen
          </button>
        </div>
      </Modal>
    </div>
  );
}
