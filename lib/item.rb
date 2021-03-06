class Item < ActiveRecord::Base
    has_one :transactions_as_donation, :foreign_key => 'donor_id', :class_name => 'User'
    has_one :transactions_as_request, :foreign_key => 'requester_id', :class_name => 'User'
    has_one :donors, through: :transactions_as_donation
    has_one :requesters, through: :transactions_as_request

    @@prompt=TTY::Prompt.new
    @@ascii=Artii::Base.new :font => 'slant'
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
    ]

    def self.add_item(user)
        puts""
        Interface.donator_logo
        name=@@prompt.ask("      What's the name of the item?     ".colorize(:background=>:blue),required: true).downcase
        puts""

        get_donated_transactions=Transaction.where(kind:"Donation")
        all_items=get_donated_transactions.map(&:item).uniq
        similar_array=all_items.select{|items| items.name.include?(name)}
        
        if(!similar_array.empty?)
            self.render_table(similar_array)
            item_on_the_list=@@prompt.select("          Is your item on this list?            ".colorize(:background=>:blue), ["Yes","No"])
            puts""

            if(item_on_the_list=="Yes")
                list_number=0
                if(similar_array.length==1)
                    list_number=1
                else
                    loop do
                        list_number=@@prompt.ask("   Type the list no. of your item, from 1-#{similar_array.length}  ".colorize(:background=>:blue)).to_i
                        break if list_number.between?(1, similar_array.length)
                        puts "Wrong input , your input should be between 1-#{similar_array.length}".colorize(:red)
                        puts""
                    end
                end

                new_quantity=self.check_quantity
                update_quantity=similar_array[list_number-1]
                update_quantity.quantity += new_quantity
                self.item_table(update_quantity,new_quantity)
                self.check_if_correct(user)
                update_quantity.save

                # Transaction.create(user_id:user.id,status:"Added",item_id:update_quantity.id,quantity:new_quantity,kind:"Donation")

                # modified Transaction class to have donor and requester ids
                Transaction.create(
                    donor_id: user.id,
                    status: "Added",
                    item_id: update_quantity.id,
                    quantity: new_quantity,
                    kind: "Donation"
                )

                self.succesful_donation(user)

            else
                check_name=@@prompt.select("   Is '#{name}' the name of the item that you wanted to add?  ".colorize(:background=>:blue), ["Yes","No"])
                if(check_name=="No")
                    self.add_item(user)
                end
            end
        end
        
        # end
        item=self.new
        item.name=name
        item.category=@@prompt.select("         Choose the category?           ".colorize(:background=>:cyan), @@category_array)
        puts""
        item.description=@@prompt.ask("        Write a short description       ".colorize(:background=>:blue),required: true)
        item.quantity=self.check_quantity
        self.item_table(item)
        self.check_if_correct(user)
        item.save
        # Transaction.create(user_id:user.id,status:"Added",item_id:item.id,quantity:item.quantity,kind:"Donation")

        # modified Transaction class to have donor and requester ids
        Transaction.create(
            donor_id: user.id,
            status: "Added",
            item_id: item.id,
            quantity: item.quantity,
            kind: "Donation"
        )
        self.succesful_donation(user)
    end
    
    # display item (table?); using pp for now
    def display
        tp self
    end

    #helper method to render tables for the similar items
    def self.render_table(similar_array)
        Interface.donator_logo
        table_array=[]
        i=1
        similar_array.each do |items|
            table_array<<[" #{i} ".colorize(:light_blue),items.name.colorize(:light_red),items.category,items.description]
            i+=1
        end
        table = TTY::Table.new [ 'List No.'.colorize(:color => :green),'ITEM NAME'.colorize(:color => :green), 'Category'.colorize(:color => :green),'Description'.colorize(:color => :green)], table_array
        puts""
        puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
        puts""

        
    end

    #helper method to render the tables for a specific transaction
    def self.item_table(item_array,quantity=nil)
        Interface.donator_logo

        if(quantity)
            table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Description'], [[item_array.name.colorize(:red),item_array.category,quantity,item_array.description]]
            puts""
            puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
            puts""
        else
            table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Description'], [[item_array.name.colorize(:red),item_array.category,item_array.quantity,item_array.description]]
            puts""
            puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
            puts""
        end
    end

    def self.succesful_donation(user)
        system('clear')
        puts"           
                    ░█▀█▀█ █── ▄▀▄ █▄─█ █─▄▀──
                    ──░█── █▀▄ █▀█ █─▀█ █▀▄───
                    ─░▄█▄─ ▀─▀ ▀─▀ ▀──▀ ▀─▀▀──
        
                    ░▀▄─────▄▀ ▄▀▄ █─█──
                    ──░▀▄─▄▀── █─█ █─█──
                    ────░█──── ─▀─ ─▀───
        "
        puts""
        puts @@ascii.asciify(user.name).colorize(:cyan)
        puts""
        puts"           Your donation was succesful.            ".colorize(:background=>:blue)
        # sleep(5)
        user.donator_menu
    end

    def self.succesful_request(transaction)

        system('clear')
        puts"           
                    ░█▀█▀█ █── ▄▀▄ █▄─█ █─▄▀──
                    ──░█── █▀▄ █▀█ █─▀█ █▀▄───
                    ─░▄█▄─ ▀─▀ ▀─▀ ▀──▀ ▀─▀▀──
        
                    ░▀▄─────▄▀ ▄▀▄ █─█──
                    ──░▀▄─▄▀── █─█ █─█──
                    ────░█──── ─▀─ ─▀───
        "
        puts""
        puts @@ascii.asciify(transaction.user.name).colorize(:cyan)
        puts""
        puts"           Your request was succesful.            ".colorize(:background=>:blue)

        transaction.display

        # sleep(5)
        transaction.user.requester_menu
    end

    # validates that the input is correct
    def self.check_quantity
        quantity=0
        loop do
            puts ""
            quantity=@@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
                    break if quantity>0
                    puts""
                    puts "          Wrong input, only numbers above zero are accepted".red
                    puts "                              TRY AGAIN"
                    puts""
            end
        quantity
    end
        
    def self.check_if_correct(user)
        correct_prompt=@@prompt.select("         Is everything correct?         ".colorize(:background=>:blue), ["Yes", "No, make changes","Changed my mind, don't want to donate!"])

        if(correct_prompt=="No, make changes")
            self.add_item(user)
        elsif(correct_prompt=="Changed my mind, don't want to donate!")
            user.donator_menu
        else
            return nil
        end

    end

    def self.render_items_matched(transactions)
        Interface.receiver_logo
        list_no = 1
        transactions.each do |transaction|
            table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Address'], [[transaction.item.name.colorize(:red),transaction.item.category,transaction.quantity,transaction.user.address]]
            puts "LIST NO. #{list_no}"
            puts table.render(
                :unicode,
                indent:8,
                alignments:[:center, :center,:center],
                width:100,
                padding: [0,1,0,1],
                resize: true
            )
            puts""
            list_no += 1
        end
    end


  
end