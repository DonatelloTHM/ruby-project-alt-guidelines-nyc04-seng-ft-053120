class Item < ActiveRecord::Base
    has_many :transactions
    has_many :users, through: :transactions
    @@prompt=TTY::Prompt.new

    # prompt user for Item attributes, returns hash of attributes
    def describe()
        # item = self.new
        self.name = @@prompt.ask("      What's the name of the item?     ".colorize(:background=>:blue))
        puts""
        self.category = @@prompt.select("         Choose the category?           ".colorize(:background=>:blue), ["Health","Tools","Electronics","Clothing"])
        puts""
        self.description = @@prompt.ask("        Write a short description       ".colorize(:background=>:blue))
        puts""
        quantity = @@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
        
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

        self.quantity = quantity
        # return item
    end

    # display item (table?); using pp for now
    def display()
        tp self
    end

    # prompt user for Item attributes, returns hash of attributes
    def self.prompt_attributes()
        prompt_attributes = Hash.new

        prompt_attributes[:name] = @@prompt.ask("      What's the name of the item?     ".colorize(:background=>:blue))
        puts""
        prompt_attributes[:category] = @@prompt.select("         Choose the category?           ".colorize(:background=>:blue), ["Health","Tools","Electronics","Clothing"])
        puts""
        prompt_attributes[:description] = @@prompt.ask("        Write a short description       ".colorize(:background=>:blue))
        puts""
        quantity = @@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
        
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

        prompt_attributes[:quantity] = quantity
        return prompt_attributes
    end

    # request item
    # will search for Item with matching name and category and transaction with status of "donated"
    # if not found, will create new item and transaction
    # if found, will promopt user to accept donation

    def self.request_item(user)

        # prompt user for item attributes
        prompt_attributes = Item.prompt_attributes()

        # return item if found with name & category match, otherwise create new item
        item = Item.find_or_initialize_by(name: prompt_attributes[:name], category: prompt_attributes[:category])

        if item.id == nil
            # item not found; creating new item
            puts "Creating Request"
            item.quantity = prompt_attributes[:quantity]
            item.description = prompt_attributes[:description]
            item.save
            transaction = Transaction.create(
                user_id: user.id,
                status: "Requested",
                item_id: item.id,
                quantity: item.quantity
            )
            item.display
            transaction.display
        else
            # item found
            # TO ADD: user option to modify existing request if created by user
            puts "Found Matching Request"
            transaction = Transaction.where(item_id: item.id)
            item.display
            transaction.display

            # if user wants existing item(s), have user confirm and accept donation
        end

    end

    def self.add_item(user) 
        prompt_attributes = Item.prompt_attributes()
        item = Item.create(prompt_attributes)
        item.save
        transaction = Transaction.create(user_id:user.id,status:"Donated",item_id:item.id,quantity:item.quantity)
        item.display
        transaction.display
        puts"           
                    ░█▀█▀█ █── ▄▀▄ █▄─█ █─▄▀──
                    ──░█── █▀▄ █▀█ █─▀█ █▀▄───
                    ─░▄█▄─ ▀─▀ ▀─▀ ▀──▀ ▀─▀▀──
        
                    ░▀▄─────▄▀ ▄▀▄ █─█──
                    ──░▀▄─▄▀── █─█ █─█──
                    ────░█──── ─▀─ ─▀───
        "
        puts""
        puts"           Your donation was succesful.            ".colorize(:background=>:blue)
        sleep(5)
    end

end


