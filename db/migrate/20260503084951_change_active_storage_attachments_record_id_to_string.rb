class ChangeActiveStorageAttachmentsRecordIdToString < ActiveRecord::Migration[8.1]
  def up
    # active_storage_attachments.record_id was bigint but all models use UUID (string) PKs.
    # SQLite silently casts UUIDs to 0 in bigint columns, breaking all photo associations.
    remove_index :active_storage_attachments,
                 name: :index_active_storage_attachments_uniqueness
    change_column :active_storage_attachments, :record_id, :string, null: false, default: ""
    add_index :active_storage_attachments,
              %i[record_type record_id name blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
  end

  def down
    remove_index :active_storage_attachments,
                 name: :index_active_storage_attachments_uniqueness
    change_column :active_storage_attachments, :record_id, :bigint, null: false
    add_index :active_storage_attachments,
              %i[record_type record_id name blob_id],
              name: :index_active_storage_attachments_uniqueness,
              unique: true
  end
end
