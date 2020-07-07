class Item < ActiveRecord::Base
    has_many :transactions
    has_many :users, through: :transactions
    @@prompt=TTY::Prompt.new

    def self.add_item(user) 
        item=self.new
        item.name=@@prompt.ask("      What's the name of the item?     ".colorize(:background=>:blue))
        puts""
        item.category=@@prompt.select("         Choose the category?           ".colorize(:background=>:blue), ["Health","Tools","Electronics","Clothing"])
        puts""
        item.description=@@prompt.ask("        Write a short description       ".colorize(:background=>:blue))
        puts""
        quantity=@@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
        
        loop do
            if(quantity>0)
                break
            else
                puts""
                puts "          Wrong input, only numbers above zero are accepted".red
                puts "                              TRY AGAIN"
                puts""
                quantity=@@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
            end
            break if quantity>0
        end

        item.quantity=quantity
        item.save
        Transaction.create(user_id:user.id,status:"Donated",item_id:item.id,quantity:item.quantity)
        binding.pry
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


