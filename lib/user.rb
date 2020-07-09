class User < ActiveRecord::Base
    has_many :transactions
    has_many :items, through: :transactions

    @@prompt=TTY::Prompt.new

    def self.user_menu(user)
        Interface.logo_no_animation
        puts"                                                                       "+"● ".green.blink+"Signed In as: "+user.username.colorize(:light_green)
        puts"            Choose your window?            "
        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Donator", -> {user.donator_menu}
            w.choice "          Requester", -> {user.requester_menu}
            w.choice "          Log out", -> {Interface.first_menu}
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

    # def self.select_one_transaction_from_array(transaction_array:, per_page: 10, choice: false)

    def select_active_request_transaction
        transactions = Transaction.where(
            'user_id = ? AND status != ? AND status != ? AND kind = ?', 
            self.id, "Closed", "Cancelled", "Request"
        )
        transaction = Interface.select_one_transaction_from_array(transaction_array: transactions)
        return transaction
    end

    def select_active_donatation_transaction
        transactions = Transaction.where(
            "kind = ? AND status = ? AND user_id != ?", 
            "Donation", "Added", self.id
        )

        new_request_choice = Hash.new
        new_request_choice[:name] = "Create a new request"
        new_request_choice[:value] = "new" # used for prompt select

        transaction = Interface.select_one_transaction_from_array(transaction_array: transactions, choice: new_request_choice)
        return transaction
    end

    # request type = "create" or "cancel" or "modify"
    def request(type)

        case type

            when "create"
                
                puts "CREATING REQUEST"
                selected_transaction = select_active_donatation_transaction

                if selected_transaction == "new"
                    # created a new donation
                    selected_transaction = Item.create_request(self)
                    selected_transaction.display
                else
                    # selected an available donation
                    selected_transaction.display
                    confirm_reserve_donation = @@prompt.select("RESERVE DONATION?  ", ["Yes", "No", "Back"])

                    if confirm_reserve_donation == "Yes"
                        selected_transaction.status = "Reserved"
                        selected_transaction.save
                        selected_transaction.display
                        sleep(5)
                        self.requester_menu
                    elsif confirm_reserve_donation == "No"
                        self.request("create")
                    else
                        self.requester_menu
                    end
                end


            when "cancel"

                puts "CANCELLING REQUEST"

                selected_transaction = select_active_request_transaction
                selected_transaction.display

                confirm_cancel_transaction = @@prompt.select("CONFIRM CANCEL?  ", ["Yes", "No", "Back"])

                if confirm_cancel_transaction == "Yes"
                    selected_transaction.status = "Cancelled"
                    selected_transaction.save
                    selected_transaction.display
                    sleep(5)
                    self.requester_menu
                elsif confirm_cancel_transaction == "No"
                    self.request("cancel")
                else
                    self.requester_menu
                end

            when "modify"

                puts "MODIFYING REQUEST"

                selected_transaction = select_active_request_transaction
                selected_transaction.display

                modified_transaction = Transaction.modify_transaction(selected_transaction)

                confirm_modify_transaction = @@prompt.select("CONFIRM CHANGES?  ", ["Yes", "No", "Back"])

                if confirm_modify_transaction == "Yes"
                    modified_transaction.save
                    modified_transaction.display
                    sleep(5)
                    self.requester_menu
                elsif confirm_modify_transaction == "No"
                    self.request("modify")
                else
                    self.requester_menu
                end

            else
                puts "*** UNKNOWN REQUEST TYPE: #{type}"
                return nil
        end

        sleep(5)
        self.requester_menu
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
            m.choice "          Make a Request", -> {self.request("create")}  #2
            m.choice "          Cancel a Request", -> {self.request("cancel")} #3
            m.choice "          Modify a Request", -> {self.request("modify")}#4
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

        if(!transactions.empty?)
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
            update_inventory=cancel_item.item.quantity-=cancel_item.quantity
            cancel_item.save
            cancel_item.item.save
            Interface.donator_logo
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                            YOUR CANCELLATION WAS SUCCESSFUL                           ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            sleep(4)
            self.donator_menu
        else
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                       NO TRANSACTIONS AVAILABLE FOR CANCELATION                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            sleep(4)
            self.donator_menu
        end
    end

    def update_quantity
        Interface.donator_logo
        transactions=self.transactions.where(status:"Added",kind:"Donation")

        if(!transactions.empty?)
            puts""
            puts"           Which item you want to update           ".colorize(:background=>:blue)
            self.render_table(transactions)
            puts""
            list_number=self.list_number_validation(transactions)

            self.render_item_correct(transactions[list_number-1])
            
            puts""
            check_if_correct=@@prompt.select("   Is this the item that you wanted to update?  ".colorize(:background=>:blue), ["Yes","No, change it.","Don't update anything"])
            if(check_if_correct=="No, change it.")
                self.cancel_donation
            elsif(check_if_correct=="Don't update anything")
                self.donator_menu
            end

            update_item=Transaction.find(transactions[list_number-1].id)
            old_quantity=update_item.quantity
            update_item.quantity=self.check_quantity
            difference=update_item.quantity-old_quantity
            update_inventory=update_item.item.quantity += difference
            update_item.save
            update_item.item.save
            Interface.donator_logo
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                               YOUR UPDATE WAS SUCCESSFUL                              ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            sleep(4)
            self.donator_menu

        else
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                           NO TRANSACTIONS AVAILABLE FOR UPDATE                        ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            sleep(4)
            self.donator_menu
        end
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

    def check_quantity
        quantity=0
        loop do
            puts ""
            quantity=@@prompt.ask("          What's the new quantity?          ".colorize(:background=>:blue)).to_i
                    break if quantity>0
                    puts""
                    puts "          Wrong input, only numbers above zero are accepted".red
                    puts "                              TRY AGAIN"
                    puts""
            end
        quantity
    end

end    