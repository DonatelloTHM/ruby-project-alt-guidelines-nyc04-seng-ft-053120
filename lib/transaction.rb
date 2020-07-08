class Transaction < ActiveRecord::Base
    belongs_to :user
    belongs_to :item

    def display
        render_table([self])
    end

    def render_table(transaction_array)

        table_array=[]
        i=1

        transaction_array.each do |transaction|
            table_array<<[
                "#{transaction.item.quantity}",
                "#{transaction.item.category}", 
                "#{transaction.item.name}"
            ]
            i+=1
        end

        table = TTY::Table.new ['QTY', 'CATEGORY', 'NAME'], table_array
        puts""
        # puts table.render()
        # puts table.render(:unicode, indent:8, alignments:[:center, :center, :center],  width:90, padding: [0,1,0,1], resize: true)
        puts table.render(
            :unicode, 
            # indent: 8, 
            alignments: [:right, :left, :left], 
            column_widths: [5, 10, 20], 
            padding: [0,1,0,1]
        )
        puts""
    end

    def self.list_all
        tp Transaction.all
    end

end