import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { getCollections, createCollection, updateCollection, deleteCollection } from '../../lib/admin-api';
import DataTable from './DataTable';
import Modal from './Modal';
import CollectionForm from './CollectionForm';

export default function CollectionManager() {
  const [collections, setCollections] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editCollection, setEditCollection] = useState<any | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await getCollections();
      setCollections(data);
    } catch (err: any) {
      setError('Kategorien konnten nicht geladen werden: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    try {
      if (editCollection) {
        await updateCollection(editCollection.id || editCollection.handle, data);
      } else {
        await createCollection(data);
      }
      setShowForm(false);
      setEditCollection(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Speichern: ' + err.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteCollection(deleteTarget.id || deleteTarget.handle);
      setDeleteTarget(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Loeschen: ' + err.message);
    }
  };

  const openEdit = (collection: any) => {
    setEditCollection(collection);
    setShowForm(true);
  };

  const openCreate = () => {
    setEditCollection(null);
    setShowForm(true);
  };

  const columns = [
    {
      key: 'title',
      label: 'Titel',
      render: (_: any, row: any) => row.title?.de || row.titleDe || row.handle || '—',
    },
    {
      key: 'handle',
      label: 'Handle',
    },
    {
      key: 'image',
      label: 'Bild',
      render: (v: any) =>
        v ? <img src={v} alt="" class="w-10 h-10 object-cover rounded border border-gray-200" /> : '—',
    },
  ];

  return (
    <div class="max-w-5xl">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-[#0f0f0f]">Kategorien</h1>
        <button
          onClick={openCreate}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-5 rounded-lg transition-colors text-sm"
        >
          + Neue Kategorie
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
          data={collections}
          emptyMessage="Noch keine Kategorien vorhanden."
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

      {/* Collection Form Modal */}
      <Modal
        open={showForm}
        title={editCollection ? 'Kategorie bearbeiten' : 'Neue Kategorie'}
        onClose={() => {
          setShowForm(false);
          setEditCollection(null);
        }}
      >
        <CollectionForm
          collection={editCollection}
          onSave={handleSave}
          onCancel={() => {
            setShowForm(false);
            setEditCollection(null);
          }}
        />
      </Modal>

      {/* Delete Confirmation */}
      <Modal
        open={!!deleteTarget}
        title="Kategorie loeschen"
        onClose={() => setDeleteTarget(null)}
      >
        <p class="text-sm text-gray-600 mb-6">
          Moechten Sie die Kategorie <strong>{deleteTarget?.title?.de || deleteTarget?.titleDe || deleteTarget?.handle}</strong> wirklich loeschen? Diese Aktion kann nicht rueckgaengig gemacht werden.
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
