class RemoveIsCapturedFromPieces < ActiveRecord::Migration[5.0]
  def change
    remove_column :pieces, :is_captured
  end
end
