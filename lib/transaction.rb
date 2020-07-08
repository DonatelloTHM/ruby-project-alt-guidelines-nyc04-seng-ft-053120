class Transaction < ActiveRecord::Base
    belongs_to :user
    belongs_to :item

    @@prompt=TTY::Prompt.new

    def display
        Transaction.render_table([self])
        # "#{transaction.kind} #{transaction.status} #{transaction.item.quantity} #{transaction.item.category} #{transaction.item.name} #{transaction.item.description}"
    end

    # render at table from an array of transaction objects. 
    # if include_selection_flag, then also create a selection prompt and return selected transaction
    #
    def self.render_table(transaction_array)

        table_array = []

        transaction_array.each_with_index do |transaction, index|
            table_array << [
                index+1,
                "#{transaction.kind}",
                "#{transaction.status}",
                "#{transaction.item.quantity}",
                "#{transaction.item.category}", 
                "#{transaction.item.name}",
                "#{transaction.item.description}"
            ]
        end

        table = TTY::Table.new ["", "KIND", "STATUS", "QTY", "CATEGORY", "NAME", "DESCRIPTION"], table_array
        puts""

        # puts table.render()
        # puts table.render(:unicode, indent:8, alignments:[:center, :center, :center],  width:90, padding: [0,1,0,1], resize: true)

        puts table.render(
            :unicode, 
            # indent: 8, 
            alignments: [:left, :left, :left, :center, :left, :left, :left], 
            column_widths: [3, 10, 10, 5, 10, 15, 20], 
            padding: [0,1,0,1]
        )
    end

    def self.modify_transaction(transaction)
        return transaction
    end

    def self.list_all
        tp Transaction.all
    end

end