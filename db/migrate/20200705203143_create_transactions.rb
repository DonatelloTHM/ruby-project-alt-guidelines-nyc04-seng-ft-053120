class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.integer :donor_id
      t.integer :requester_id
      t.string :status
      t.string :kind
      t.integer :item_id
      t.integer :quantity
      t.timestamps
    end
  end
end
