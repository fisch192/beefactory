import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { getProducts, getCollections, createProduct, updateProduct, deleteProduct } from '../../lib/admin-api';
import DataTable from './DataTable';
import Modal from './Modal';
import ProductForm from './ProductForm';

export default function ProductManager() {
  const [products, setProducts] = useState<any[]>([]);
  const [collections, setCollections] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editProduct, setEditProduct] = useState<any | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');
      const [prods, colls] = await Promise.all([getProducts(), getCollections()]);
      setProducts(prods);
      setCollections(colls);
    } catch (err: any) {
      setError('Produkte konnten nicht geladen werden: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: any) => {
    try {
      if (editProduct) {
        await updateProduct(editProduct.id || editProduct.handle, data);
      } else {
        await createProduct(data);
      }
      setShowForm(false);
      setEditProduct(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Speichern: ' + err.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteProduct(deleteTarget.id || deleteTarget.handle);
      setDeleteTarget(null);
      await loadData();
    } catch (err: any) {
      alert('Fehler beim Loeschen: ' + err.message);
    }
  };

  const openEdit = (product: any) => {
    setEditProduct(product);
    setShowForm(true);
  };

  const openCreate = () => {
    setEditProduct(null);
    setShowForm(true);
  };

  const columns = [
    {
      key: 'title',
      label: 'Titel',
      render: (_: any, row: any) => row.title?.de || row.titleDe || row.handle || '—',
    },
    {
      key: 'price',
      label: 'Preis',
      render: (v: any) => v != null ? `${Number(v).toFixed(2)} EUR` : '—',
    },
    {
      key: 'collection',
      label: 'Kategorie',
      render: (v: any, row: any) => {
        const handle = v || row.collectionHandle || '';
        const coll = collections.find((c) => c.handle === handle || c.id === handle);
        return coll?.title?.de || coll?.titleDe || handle || '—';
      },
    },
  ];

  return (
    <div class="max-w-5xl">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-[#0f0f0f]">Produkte</h1>
        <button
          onClick={openCreate}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-5 rounded-lg transition-colors text-sm"
        >
          + Neues Produkt
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
          data={products}
          emptyMessage="Noch keine Produkte vorhanden."
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

      {/* Product Form Modal */}
      <Modal
        open={showForm}
        title={editProduct ? 'Produkt bearbeiten' : 'Neues Produkt'}
        onClose={() => {
          setShowForm(false);
          setEditProduct(null);
        }}
      >
        <ProductForm
          product={editProduct}
          collections={collections}
          onSave={handleSave}
          onCancel={() => {
            setShowForm(false);
            setEditProduct(null);
          }}
        />
      </Modal>

      {/* Delete Confirmation */}
      <Modal
        open={!!deleteTarget}
        title="Produkt loeschen"
        onClose={() => setDeleteTarget(null)}
      >
        <p class="text-sm text-gray-600 mb-6">
          Moechten Sie das Produkt <strong>{deleteTarget?.title?.de || deleteTarget?.titleDe || deleteTarget?.handle}</strong> wirklich loeschen? Diese Aktion kann nicht rueckgaengig gemacht werden.
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
