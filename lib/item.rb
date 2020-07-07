class Item < ActiveRecord::Base
    has_many :transactions
    has_many :users, through: :transactions
    @@prompt=TTY::Prompt.new
    @@ascii=Artii::Base.new :font => 'roman'

def self.add_item(user)
    puts""
    name=@@prompt.ask("      What's the name of the item?     ".colorize(:background=>:blue)).downcase
    puts""
    similar_array=self.where("name like ?", "%#{name}%")   #returns an array with instances of the item that have a similar name
    
    if(!similar_array.empty?)
    self.render_table(similar_array)
    item_on_the_list=@@prompt.select("   Is your item anywhere on this list?  ".colorize(:background=>:blue), ["Yes","No"])
    puts""
        if(item_on_the_list=="Yes")
            list_number=0
            loop do
                list_number=@@prompt.ask("   Type the list no. of your item, from 1-#{similar_array.length}  ".colorize(:background=>:blue)).to_i
                break if list_number.between?(1, similar_array.length)
                puts "Wrong input , your input should be between 1-#{similar_array.length}".colorize(:red)
                puts""
            end
            
            
            new_quantity=self.check_quantity
            update_quantity=similar_array[list_number-1]
            update_quantity.quantity += new_quantity
             self.item_table(update_quantity,new_quantity)
            update_quantity.save
            Transaction.create(user_id:user.id,status:"Donated",item_id:update_quantity.id,quantity:new_quantity)
            self.succesful_donation(user)
        else
            puts""
            check_name=@@prompt.select("   Is '#{name}' the name of the item that you wanted to add?  ".colorize(:background=>:blue), ["Yes","No"])
            if(check_name=="No")
                name=@@prompt.ask("      What's the new name?     ".colorize(:background=>:blue)).downcase
            end
        end
    end
    item=self.new
    item.name=name
    puts""
    item.category=@@prompt.select("         Choose the category?           ".colorize(:background=>:blue), ["Health","Tools","Electronics","Clothing"])
    puts""
    item.description=@@prompt.ask("        Write a short description       ".colorize(:background=>:blue))
    puts""

    item.quantity=self.check_quantity
    self.item_table(item)
    #Add a prompt to check if everything is correct
    binding.pry
    item.save
    Transaction.create(user_id:user.id,status:"Donated",item_id:item.id,quantity:item.quantity)
    self.succesful_donation(user)
end
def self.render_table(similar_array)
    table_array=[]
    i=1
    similar_array.each do |items|
        table_array<<[" #{i} ".colorize(:light_blue),items.name.colorize(:light_red),items.category,items.description]
        i+=1
    end
    table = TTY::Table.new [ 'List No.','ITEM NAME'.colorize(:color => :green), 'Category','Description'], table_array
    puts""
    puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
    puts""

    
end

def self.item_table(item_array,quantity=nil)

    if(quantity)
        table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Description'], [[item_array.name,item_array.category,quantity,item_array.description]]
        puts""
        puts table.render(:unicode,indent:8,alignments:[:center, :center,:center],  width:90, padding: [0,1,0,1],resize: true)
        puts""
    else
        table = TTY::Table.new ['ITEM NAME'.colorize(:color => :green),'Category','Quantity','Description'], [[item_array.name,item_array.category,item_array.quantity,item_array.description]]
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
    sleep(5)
    user.donator_menu
end

def self.check_quantity
    quantity=0
    loop do
        quantity=@@prompt.ask("          What's the quantity?          ".colorize(:background=>:blue)).to_i
                break if quantity>0
                puts""
                puts "          Wrong input, only numbers above zero are accepted".red
                puts "                              TRY AGAIN"
                puts""
        end
    quantity
    end
end


