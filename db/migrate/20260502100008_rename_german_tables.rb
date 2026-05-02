class RenameGermanTables < ActiveRecord::Migration[8.1]
  def change
    # F10: Abstimmungen → Polls
    rename_table :abstimmungen,       :polls
    rename_table :abstimmung_optionen, :poll_options
    rename_table :stimmen,             :votes

    # Rename FK columns produced by references
    rename_column :poll_options, :abstimmung_id,        :poll_id
    rename_column :votes,        :abstimmung_option_id,  :poll_option_id

    # Rename poll_type enum values (einfach/mehrfach → single/multiple)
    # and status values (offen/geschlossen → open/closed)
    reversible do |dir|
      dir.up do
        execute "UPDATE polls SET poll_type = 'single'   WHERE poll_type = 'einfach'"
        execute "UPDATE polls SET poll_type = 'multiple' WHERE poll_type = 'mehrfach'"
        execute "UPDATE polls SET status    = 'open'     WHERE status    = 'offen'"
        execute "UPDATE polls SET status    = 'closed'   WHERE status    = 'geschlossen'"
      end
      dir.down do
        execute "UPDATE polls SET poll_type = 'einfach'     WHERE poll_type = 'single'"
        execute "UPDATE polls SET poll_type = 'mehrfach'    WHERE poll_type = 'multiple'"
        execute "UPDATE polls SET status    = 'offen'       WHERE status    = 'open'"
        execute "UPDATE polls SET status    = 'geschlossen' WHERE status    = 'closed'"
      end
    end

    # Default values need updating too
    change_column_default :polls, :poll_type, from: "einfach", to: "single"
    change_column_default :polls, :status,    from: "offen",   to: "open"

    # F12: Mitteilungen → Messages
    rename_table :mitteilungen,    :messages
    rename_table :mitteilung_groups, :message_groups
    rename_table :posteingaenge,   :inbox_entries

    rename_column :message_groups, :mitteilung_id, :message_id
    rename_column :inbox_entries,  :mitteilung_id, :message_id
  end
end
