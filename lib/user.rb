class User < ActiveRecord::Base
    has_many :items, :class_name => 'Transaction', :foreign_key => 'item_id'
    has_many :donations, :class_name => 'Transaction', :foreign_key => 'donor_id'
    has_many :requests, :class_name => 'Transaction', :foreign_key => 'requester_id'

    @@prompt=TTY::Prompt.new

    @@category_array = [
        "Others",
        "Cars",
        "Books",
        "Health",
        "Tools",
        "Electronics",
        "Clothing",
        "Appliances",
        "Furniture"
    ];

    def self.user_menu(user)
        Interface.logo_no_animation
        puts"                                                                       "+"● ".green.blink+"Signed In as: "+user.username.colorize(:light_green)
        puts"            Choose your window?            "
        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Donator", -> {user.donator_menu}
            w.choice "          Requester", -> {user.requester_menu}
            w.choice "          Settings",->{user.options_menu}
            w.choice "          Log out", -> {Interface.first_menu}
            w.choice "          Quit".red, -> {Interface.quit(user)}
        end
        # return nil
    end

    # display using table_print
    def display
        tp self
    end

    def select_reserved_transaction

        transactions = Transaction.where(
            'requester_id = ? AND status = ?', 
            self.id, "Reserved"
        )

        transaction = Interface.select_one_transaction_from_array(
            prompt_text: "\nSELECT A REQUEST\n",
            transaction_array: transactions
        )

        return transaction
    end

    def select_active_request_transaction

        transactions = Transaction.where(
            'requester_id = ? AND kind = ? AND status != ? AND status != ? AND status != ?', 
            self.id, "Request", "Closed", "Cancelled", "Completed"
        )

        transaction = Interface.select_one_transaction_from_array(
            prompt_text: "\nSELECT A REQUEST\n",
            transaction_array: transactions
        )

        return transaction
    end

    def select_active_donatation_transaction
        
        transactions = Transaction.where(
            "kind = ? AND status = ? AND donor_id != ?", 
            "Donation", "Added", self.id
        )

        new_request_choice = Hash.new
        new_request_choice[:name] = "Create a new request"
        new_request_choice[:value] = "new" # used for prompt select

        transaction = Interface.select_one_transaction_from_array(
            prompt_text: "\nSELECT AN AVAILABE DONATION or MAKE A NEW REQUEST\n",
            transaction_array: transactions, 
            choice: new_request_choice
        )
        return transaction
    end

    def prompt_attributes

        item_attributes = Hash.new

        item_attributes[:name] = @@prompt.ask("Name?")

        #check if matching request name exists for user

        possible_matching_requests = self.requests.select do |request_transaction|
            request_transaction.status != "Cancelled" && request_transaction.item.name.match?(/#{item_attributes[:name]}/i)
        end

        if (possible_matching_requests.length > 0)

            puts "\nYour possible matching open request(s)\n"

            Transaction.render_table(possible_matching_requests)

            answer = @@prompt.select("", ["MODIFY A REQUEST", "CREATE A DIFFERENT REQUEST", "CONTINUE WITH THIS NEW REQUEST", "Back"])

            if (answer != "CONTINUE WITH THIS REQUEST")
                return answer
            else
                puts "CONTINUING WITH THIS REQUEST"
            end
        end

        puts""

        item_attributes[:category] = @@prompt.select("Category?", @@category_array)
        puts""

        item_attributes[:description] = @@prompt.ask("Description?")
        puts""

        quantity = @@prompt.ask("Quantity?").to_i
        
        loop do
            if(quantity>0)
                break
            else
                puts""
                puts "          Wrong input, only numbers above zero are accepted".red
                puts "                              TRY AGAIN"
                puts""
                quantity = @@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
            end
            break if quantity>0
        end

        item_attributes[:quantity] = quantity
        return item_attributes
    end

    def reserve_complete_matching_donation(donation)

        confirm_reserve_donation = @@prompt.select("RESERVE DONATION?  ", ["Yes", "No", "Back"])

        if confirm_reserve_donation == "Yes"
            
            donation.status = "Reserved"
            donation.requester_id = self.id
            donation.save

            system("clear")

            puts "\nDONATION RESERVED\n"

            donation.display

            @@prompt.keypress("Press any key to continue")

            confirm_complete_donation = @@prompt.select("COMPLETE DONATION?  ", ["Yes", "No", "Back"])

            if confirm_complete_donation == "Yes"
                self.request(type: "complete", input_transaction: donation)
            elsif confirm_reserve_donation == "No"
                self.request(type: "create")
            else
                self.requester_menu
            end

        elsif confirm_reserve_donation == "No"
            self.request(type: "create")
        else
            self.requester_menu
        end
    end

    # request type = "create" or "cancel" or "modify"
    def request(type:, input_transaction: false)

        self.requests.reload
        self.donations.reload
        system("clear")

        case type

            when "create"

                active_donation = input_transaction ? input_transaction : select_active_donatation_transaction

                if active_donation == "new"

                    # prompt user for item attributes
                    item_attributes = prompt_attributes

                    if item_attributes == "Back"
                        self.requester_menu
                        return
                    elsif item_attributes == "MODIFY A REQUEST"
                        self.request(type: "modify")
                        return
                    elsif item_attributes == "CREATE NEW REQUEST"
                        self.request(type: "create")
                        return
                    end

                    # return item if found with name, quantity & category match, otherwise create new item
                    item = Item.find_or_initialize_by(
                        name: item_attributes[:name], 
                        category: item_attributes[:category],
                        quantity: item_attributes[:quantity]
                    )

                    if item.id != nil
                        matching_donation = Transaction.where(
                            item_id: item.id
                        ).take

                        if matching_donation != nil && matching_donation.kind == "Donation" && matching_donation.status == "Added"
                            system("clear")
                            puts "\nFound Matching Donation\n"
                            matching_donation.display

                            reserve_complete_matching_donation(matching_donation)

                        end
                    end

                    # item not found; creating new item

                    system("clear")
                    puts "\nCreating Request\n"

                    item.quantity = item_attributes[:quantity]
                    item.description = item_attributes[:description]
                    item.save

                    new_request = Transaction.create(
                        requester_id: self.id,
                        status: "Open",
                        item_id: item.id,
                        quantity: item.quantity,
                        kind: "Request"
                    )

                    puts "\nREQUEST CREATED\n"
                    new_request.display

                    @@prompt.keypress("Press any key to continue")

                    self.requester_menu

                elsif active_donation == nil
                    @@prompt.keypress("\n\nNO REQUESTS CREATED\nPress any key to continue")
                    self.requester_menu
                else
                    active_donation.display
                    reserve_complete_matching_donation(active_donation)
                end

            when "cancel"

                active_request = input_transaction ? input_transaction : select_active_request_transaction

                if active_request == nil

                    puts "\nNO REQUESTS TO CANCEL\n"

                else
                    puts "\nCANCELLING REQUEST\n"

                    active_request.display

                    confirm_cancel_transaction = @@prompt.select("CONFIRM CANCEL?  ", ["Yes", "No", "Back"])

                    if confirm_cancel_transaction == "Yes"
                        active_request.status = "Cancelled"
                        active_request.save

                        system("clear")
                        puts "\nREQUEST CANCELLED\n"
                        active_request.display

                        @@prompt.keypress("Press any key to continue")

                        self.requester_menu
                    elsif confirm_cancel_transaction == "No"
                        self.request(type: "cancel")
                    else
                        self.requester_menu
                    end
                end

            when "modify"

                active_request = input_transaction ? input_transaction : select_active_request_transaction

                if active_request == nil
                    puts "\nNO REQUESTS TO MODIFY\n"
                else
                    system("clear")
                    puts "\nMODIFYING REQUEST\n"
                    active_request.display

                    modified_transaction = Transaction.modify_transaction(active_request)

                    system("clear")
                    puts "\nCONFIRMING CHANGES\n"
                    modified_transaction.display

                    confirm_modify_transaction = @@prompt.select("CONFIRM CHANGES?  ", ["Yes", "No", "Back"])

                    if confirm_modify_transaction == "Yes"

                        modified_transaction.item.save
                        modified_transaction.save

                        system("clear")
                        puts "\nREQUEST MODIFIED\n"
                        modified_transaction.display
                        @@prompt.keypress("Press any key to continue")

                        self.requester_menu

                    elsif confirm_modify_transaction == "No"
                        self.request(type: "modify")
                    else
                        self.requester_menu
                    end
                end

            when "complete"

                system("clear")
                reserved_donation = input_transaction ? input_transaction : select_reserved_transaction

                if reserved_donation == nil
                    system("clear")
                    puts "\nNO RESERVED DONATIONS TO COMPLETE\n\n"
                else

                    system("clear")
                    puts "\nCOMPLETING REQUEST/DONATION\n"
                    reserved_donation.display

                    completed_donation = Transaction.complete_transaction(reserved_donation)

                    system("clear")

                    puts "\nDONATION COMPLETION PENDING\n"
                    completed_donation.display

                    confirm_complete_transaction = @@prompt.select("\n== CONFIRM COMPLETE? ==\n== CANNOT BE UNDONE ==\n", ["Yes", "No", "Back"])

                    if confirm_complete_transaction == "Yes"

                        completed_donation.item.save
                        completed_donation.save

                        system("clear")

                        puts "\nDONATION COMPLETED\n"
                        completed_donation.display

                        @@prompt.keypress("\nPress any key to continue\n")
                        
                        self.requester_menu

                    elsif confirm_complete_transaction == "No"
                        self.request(type: "complete")
                    else
                        self.requester_menu
                    end
                end

            else
                puts "\n*** UNKNOWN REQUEST TYPE: #{type}\n"
                return nil
        end

        @@prompt.keypress("Press any key to continue")
        self.requester_menu
    end

    def view_requests

        transactions = Transaction.where(requester_id: self.id)

        if transactions == []
            puts "\nNO REQUESTS EXIST\n".colorize(:background=>:red)
        else
            Transaction.render_table(transactions)
        end

        @@prompt.keypress("Press any key to continue")
        self.requester_menu
    end

    def requester_menu
        Interface.receiver_logo
        puts""
        puts "          Requester's Main Menu          ".colorize(:background=>:red)
        @@prompt.select("", active_color: :green, per_page: 10) do |m|
            m.enum "."
            m.choice "          Make a Request", -> {self.request(type: "create")}
            m.choice "          Cancel a Request", -> {self.request(type: "cancel")}
            m.choice "          Modify a Request", -> {self.request(type: "modify")}
            m.choice "          Complete a Request", -> {self.request(type: "complete")}
            m.choice "          View all my Requests", -> {self.view_requests}
            m.choice "          Previous menu",-> {User.user_menu(self)}
            m.choice "          Quit".red, ->{Interface.quit(self)}
        end
        puts""
    end

    def donator_menu
        Interface.donator_logo
        puts""
        puts "          Donator's Main Menu          ".colorize(:background=>:green)
        @@prompt.select("",active_color: :green, per_page: 10) do |m|
            m.enum "."
            m.choice "          Make a Donation", -> {Item.add_item(self)}  #2
            m.choice "          Cancel a Donation", -> {self.cancel_donation} #3
            m.choice "          Update quantity", -> {self.update_quantity}#4
            m.choice "          View all my Donations", -> {self.view_donations}
            # m.choice "          Previous menu",-> {self.class.user_menu(self)}
            m.choice "          Previous menu",-> {User.user_menu(self)}
            m.choice "          Quit".red, ->{Interface.quit(self)}
        end
        puts""
    end

    def cancel_donation
        Interface.donator_logo

        # transactions = self.transactions.where(status:"Added",kind:"Donation")
        transactions = self.donations.where(status:"Added",kind:"Donation")

        if(!transactions.empty?)
            puts""
            if(transactions.length==1)
                list_number=1
            else
            puts"           Which item you want to cancel           ".colorize(:background=>:blue)
            self.render_table(transactions)
            puts""
            list_number=self.list_number_validation(transactions)
            end
            self.render_item_correct(transactions[list_number-1])
            
            puts""
            if(transactions.length==1)
                check_if_correct=@@prompt.select("   Is this the item that you wanted to cancel?  ".colorize(:background=>:blue), ["Yes","Don't cancel anything"])
                if(check_if_correct=="Don't cancel anything")
                    self.donator_menu
                end
            else
                check_if_correct=@@prompt.select("   Is this the item that you wanted to cancel?  ".colorize(:background=>:blue), ["Yes","No, change it.","Don't cancel anything"])
                if(check_if_correct=="No, change it.")
                    self.cancel_donation
                elsif(check_if_correct=="Don't cancel anything")
                    self.donator_menu
                end
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
        transactions=self.donations.where(status:"Added",kind:"Donation")

        if(!transactions.empty?)
            puts""
            if(transactions.length==1)
                list_number=1
            else
                puts"           Which item you want to update           ".colorize(:background=>:blue)
                self.render_table(transactions)
                puts""
                list_number=self.list_number_validation(transactions)
            end
            self.render_item_correct(transactions[list_number-1])
            
            puts""
            if(transactions.length==1)
                check_if_correct=@@prompt.select("   Is this the item that you wanted to update?  ".colorize(:background=>:blue), ["Yes","Don't update anything"])
                if(check_if_correct=="Don't update anything")
                    self.donator_menu
                end
            else
                check_if_correct=@@prompt.select("   Is this the item that you wanted to update?  ".colorize(:background=>:blue), ["Yes","No, change it.","Don't update anything"])
                if(check_if_correct=="No, change it.")
                    self.cancel_donation
                elsif(check_if_correct=="Don't update anything")
                    self.donator_menu
                end
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
                table_array<<[" #{i} ".colorize(:light_blue),transaction.item.name.colorize(:color => :red),transaction.item.category,transaction.quantity,transaction.created_at.to_s[0..9]]
                i+=1 
            end
            table = TTY::Table.new [ 'List No.'.colorize(:color => :green),'ITEM NAME'.colorize(:color => :green), 'Category'.colorize(:color => :green),'Quantity'.colorize(:color => :green),'Date Added'.colorize(:color => :green)], table_array
            puts""
            puts table.render(:unicode,indent:8,alignments:[:center, :center,:center,:center],  width:80, padding: [0,1,0,1],resize: true)
            puts""   
    end

    def render_item_correct(transaction)
        Interface.donator_logo

            table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category'.colorize(:color => :green),'Quantity'.colorize(:color => :green),'Date Added'.colorize(:color => :green)], [[transaction.item.name.colorize(:red),transaction.item.category,transaction.quantity,transaction.created_at.to_s[0..9]]]
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

    def options_menu
        Interface.logo_no_animation
        
        @@prompt.select("",active_color: :green) do |w|
            w.choice "  Change your name", -> {self.change_name}
            w.choice "  Change your address", -> {self.change_address}
            w.choice "  Change your password",->{self.change_password}
            w.choice "  Go Back", -> {User.user_menu(self)}
            w.choice "  Delete Account".red, -> {self.delete_account}
        end

        


    end

    def change_name
        Interface.logo_no_animation
        puts "                     "+"      What's your new name?     "
        puts "                     _________________________________".colorize(:red)
        changed_name=@@prompt.ask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Save"
            w.choice "          No, Go back", -> {self.options_menu}
        end
            self.name=changed_name
            self.save
            self.options_menu
    end

    def change_address
        Interface.logo_no_animation
        puts "                     "+"      What's your new address?     "
        puts "                     ____________________________________".colorize(:red)
        changed_address=@@prompt.ask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Save"
            w.choice "          No, Go back", -> {self.options_menu}
        end
            self.address=changed_address
            self.save
            self.options_menu
    end

    def change_password
        Interface.logo_no_animation
        puts "                     "+"      What's your current password?     "
        puts "                     ___________________________________________".colorize(:red)
        current_password=@@prompt.mask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        
        if (self.password != current_password)
            puts"                     "+"          WRONG PASSWORD         ".colorize(:background=>:light_red)
            rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Try again", -> {self.change_password}
            w.choice "          Go back", -> {self.options_menu}
            end
        else
            puts""
            puts "                     "+"      Type your new password?     "
            puts "                     ___________________________________________".colorize(:red)
            new_password=@@prompt.mask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)do |q|
            q.validate{|input| input.length >= 6}
            q.messages[:valid?] = 'Password should be 6 or more characters long'
            end

            choices= @@prompt.select("     ",active_color: :green) do |w|
                w.choice "          Save"
                w.choice "          No, Go back", -> {self.options_menu}
            end
            
            self.password=new_password
            self.save
            self.options_menu

        end
    end

    def delete_account
        Interface.logo_no_animation
        puts "                     "+"      Type your password     "
        puts "                     ______________________________________".colorize(:red)
        current_password=@@prompt.mask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        
        if (self.password != current_password)
            puts"                     "+"          WRONG PASSWORD         ".colorize(:background=>:light_red)
            rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Try again", -> {self.change_password}
            w.choice "          Go back", -> {self.options_menu}
            end
        else
            Interface.logo_no_animation
            puts""
            puts"               "+"                                                                           ".colorize(:background=>:light_red)                                                                                       
            puts"               "+"          IF YOU CONTINUE THIS ACCOUNT WILL BE DELETED PERMANENTLY         ".colorize(:background=>:light_red)
            puts"               "+"                                                                           ".colorize(:background=>:light_red)
            puts""
            choices= @@prompt.select("     ",active_color: :green) do |w|
                w.choice "          Changed my mind, Go back", -> {self.options_menu}
                w.choice "          DELETE ACCOUNT".colorize(:red)
            end
            Transaction.where(donor_id:self.id,status:"Completed").update_all(donor_id:nil)
            Transaction.where(donor_id:self).destroy_all
            self.destroy
            Interface.first_menu
        end
    end



    def view_donations
        Interface.donator_logo
        added=Transaction.where(donor_id:self.id,status:"Added")
        reserved=Transaction.where(donor_id:self.id,status:"Reserved")
        completed=Transaction.where(donor_id:self.id,status:"Completed")
        show_all=Transaction.where(donor_id:self.id)

        puts"            Which transactions do you want to see?            "
        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Unclaimed donations", -> {self.render_table_all_donations(added)}
            w.choice "          Reserved donations", -> {self.render_table_all_donations(reserved)}
            w.choice "          Completed donations",->{self.render_table_all_donations(completed)}
            w.choice "          All donations", -> {self.render_table_all_donations(show_all)}
            w.choice "          Go back".red, -> {self.donator_menu}
        end

        binding.pry


    end


    def render_table_all_donations(transactions)
        Interface.donator_logo
        puts""
        if(transactions.empty?)
        puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                             THERE ARE NO DONATIONS TO SHOW                            ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts"                                                                                       ".colorize(:background=>:blue)
            puts""
        else
            table_array=[]
        i=1
        transactions.each do |transaction|
            table_array<<[" #{i} ".colorize(:light_blue),transaction.status,transaction.item.name.colorize(:color => :red),transaction.item.category,transaction.quantity,transaction.created_at.to_s[0..9]]
            i+=1 
        end
        table = TTY::Table.new [ 'List No.'.colorize(:color => :green),'STATUS'.colorize(:color => :green),'ITEM NAME'.colorize(:color => :green), 'Category'.colorize(:color => :green),'Quantity'.colorize(:color => :green),'Date Added'.colorize(:color => :green)], table_array
        puts""
        puts table.render(:unicode,indent:8,alignments:[:center, :center,:center,:center],  width:80, padding: [0,1,0,1],resize: true)
        puts""  
    end
    puts""
        puts"            Choose your window?            ".colorize(:red)
        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Go back", -> {self.view_donations}
            w.choice "          Donator Menu", -> {self.donator_menu}
            w.choice "          Main menu",->{User.user_menu(self)}
        end


    end



end    