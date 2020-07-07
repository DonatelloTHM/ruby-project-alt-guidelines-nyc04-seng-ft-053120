class AddTypeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :type, :string
  end
end
