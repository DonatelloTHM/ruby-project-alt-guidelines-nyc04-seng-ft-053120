class Transaction < ActiveRecord::Base
    belongs_to :item, :class_name => 'Item'
    belongs_to :donor, :class_name => 'User'
    belongs_to :requester, :class_name => 'User'

    @@prompt=TTY::Prompt.new

    def display
        Transaction.render_table([self])
    end

    def self.check_for_matching_transaction(transaction)

        matching_transaction_kind = transaction.kind == "Request" ? "Donation" : "Request"

        matching_transaction_status = nil
        
        if transaction.kind == "Request"
            matching_transaction_status = "Added"
        else
            matching_transaction_status = "Open"
        end

        transactions = Transaction.where(
            'status = ? AND kind = ? AND quantity = ?', 
            matching_transaction_status, matching_transaction_kind, transaction.quantity
        )
        return transactions
    end

    # render at table from an array of transaction objects. 
    # if include_selection_flag, then also create a selection prompt and return selected transaction
    #
    def self.render_table(transaction_array)

        table_array = []

        transaction_array.each_with_index do |transaction, index|

            matched_transaction = Transaction.check_for_matching_transaction(transaction).take

            table_array << [
                index+1,
                "#{matched_transaction != nil}",
                "#{transaction.kind}",
                "#{transaction.status}",
                "#{transaction.item.quantity}",
                "#{transaction.item.category}", 
                "#{transaction.item.name}",
                "#{transaction.item.description}"
            ]
        end

        table = TTY::Table.new ["", "MATCH", "KIND", "STATUS", "QTY", "CATEGORY", "NAME", "DESCRIPTION"], table_array
        puts""

        puts table.render(
            :unicode, 
            alignments: [:left, :left, :left, :left, :center, :left, :left, :left], 
            column_widths: [3, 5, 10, 10, 5, 10, 15, 20], 
            padding: [0,1,0,1]
        )
    end

    def self.modify_transaction(transaction)
        transaction.item.description = @@prompt.ask("Description?", default: transaction.item.description)
        transaction.item.quantity = @@prompt.ask("Quantity?", default: transaction.item.quantity)
        transaction.item.category = @@prompt.ask("Category?", default: transaction.item.category)
        return transaction
    end

    def self.complete_transaction(transaction)
        transaction.status = "Completed"
        return transaction
    end

    def self.list_all
        tp Transaction.all
    end

end