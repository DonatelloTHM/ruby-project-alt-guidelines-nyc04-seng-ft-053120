class User < ActiveRecord::Base
    has_many :transactions
    has_many :items, through: :transactions

    @@prompt=TTY::Prompt.new

    def self.user_menu(user)
        Interface.logo
        puts"           Choose your window?            "
        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Donator", -> {user.donator_menu}
            w.choice "          Requester", -> {user.requester_menu}
            w.choice "          Quit".red, -> {Interface.quit}
        end
        # return nil
    end

    # display using table_print
    def display
        tp self
    end
    
    def list_transactions
        self.transactions
    end

    # modification_type = "cancel" or "modify" or "close"
    def modify_request(modification_type)

        transactions = Transaction.where(
            'user_id = ? AND status != ? AND status != ? AND kind = ?', 
            self.id, "Closed", "Cancelled", "Request"
        )

        selected_transaction = Interface.select_one_transaction_from_array(transactions)

        case modification_type

        when "cancel"
            puts "CANCELLING TRANSACTION"

            selected_transaction.display

            confirm_cancel_transaction = @@prompt.select("CONFIRM CANCEL?  ", ["Yes", "No", "Back"])

            if confirm_cancel_transaction == "Yes"
                selected_transaction.status = "Cancelled"
                selected_transaction.save
                selected_transaction.display
                sleep(5)
                self.requester_menu
            elsif confirm_cancel_transaction == "No"
                self.modify_request("cancel")
            else
                self.requester_menu
            end

        when "modify"

            puts "MODIFYING TRANSACTION"
            selected_transaction.display
            selected_transaction = Transaction.modify_transaction(selected_transaction)

            confirm_modify_transaction = @@prompt.select("CONFIRM CHANGES?  ", ["Yes", "No", "Back"])

            if confirm_modify_transaction == "Yes"
                selected_transaction.save
                selected_transaction.display
                sleep(5)
                self.requester_menu
            elsif confirm_modify_transaction == "No"
                self.modify_request("modify")
            else
                self.requester_menu
            end

        else
            puts "*** UNKNOWN modification_type: #{modification_type}"
            return nil
        end

        
        return nil
    end

    def view_requests
        transactions = Transaction.where(user_id: self.id, kind:"Request")
        Transaction.render_table(transactions)
        back = @@prompt.select("", ["Back"])
        self.requester_menu
    end

    def find_transaction_by_item_name(item_name)
        transaction = Transaction.where(user_id: self.id).take
        transaction.display
        return transaction
    end

    def requester_menu
        Interface.receiver_logo
        puts""
        puts "          Requester's Main Menu          ".colorize(:background=>:red)
        @@prompt.select("",active_color: :green) do |m|
            m.enum "."
            m.choice "          Make a Request", -> {Item.rrequest_item(self)}  #2
            m.choice "          Cancel a Request", -> {self.modify_request("cancel")} #3
            m.choice "          Modify a Request", -> {self.modify_request("modify")}#4
            m.choice "          View all my Requests", -> {self.view_requests}
            m.choice "          Previous menu",-> {self.class.user_menu(self)}
            m.choice "          Quit".red, ->{Interface.quit}
        end
        puts""
    end

    def donator_menu
        Interface.donator_logo
        puts""
        puts "          Donator's Main Menu          ".colorize(:background=>:green)
        @@prompt.select("",active_color: :green) do |m|
            m.enum "."
            m.choice "          Make a Donation", -> {Item.add_item(self)}  #2
            m.choice "          Cancel a Donation", -> {self.cancel_donation} #3
            m.choice "          Update quantity", -> {self.update_quantity}#4
            m.choice "          View all my Donations", -> {self.view_donations}
            m.choice "          Previous menu",-> {self.class.user_menu(self)}
            m.choice "          Quit".red, ->{Interface.quit}
        end
        puts""
    end

    def cancel_donation
        Interface.donator_logo
        transactions=self.transactions.where(status:"Added",kind:"Donation")
        puts""
        puts"           Which item you want to cancel           ".colorize(:background=>:blue)
        self.render_table(transactions)
        puts""
        list_number=self.list_number_validation(transactions)
        self.render_item_correct(transactions[list_number-1])
        
        puts""
        check_if_correct=@@prompt.select("   Is this the item that you wanted to cancel?  ".colorize(:background=>:blue), ["Yes","No, change it.","Don't cancel anything"])
        if(check_if_correct=="No, change it.")
            self.cancel_donation
        elsif(check_if_correct=="Don't cancel anything")
            self.donator_menu
        end
        cancel_item=Transaction.find(transactions[list_number-1].id)
        cancel_item.status="Canceled"
        cancel_item.save
    end

    def render_table(transactions)

            table_array=[]
            i=1
            transactions.each do |transaction|
                table_array<<[" #{i} ".colorize(:light_blue),transaction.item.name,transaction.item.category,transaction.created_at.to_s[0..9]]
                i+=1 
            end
            table = TTY::Table.new [ 'List No.','ITEM NAME'.colorize(:color => :green), 'Category','Date Added'], table_array
            puts""
            puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:80, padding: [0,1,0,1],resize: true)
            puts""   
    end

    def render_item_correct(transaction)
        Interface.donator_logo

            table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Date Added'], [[transaction.item.name.colorize(:red),transaction.item.category,transaction.quantity,transaction.created_at.to_s[0..9]]]
            puts""
            puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
            puts""
    end

    def list_number_validation(transactions)
        list_number=0
            loop do
                list_number=@@prompt.ask("   Type the list no. of your item, from 1-#{transactions.length}  ".colorize(:background=>:blue)).to_i
                break if list_number.between?(1, transactions.length)
                puts "Wrong input , your input should be between 1-#{transactions.length}".colorize(:red)
                puts""
            end
        list_number
    end

end    