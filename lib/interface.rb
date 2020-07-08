 class Interface

    @@prompt=TTY::Prompt.new
    @@test_mode = true
    
    def self.quit
        puts "QUITTING ..."
        exit(true)
    end

    def self.login_signup

        puts "LOGIN / SIGN UP"

        user = @@prompt.select("",active_color: :green) do |w|
            w.choice "          Login", -> {login}
            w.choice "          Sign Up".cyan, -> {signup}
            w.choice "          Quit".red, -> {quit}  #1
        end

        # user == nil means login failed
        # what should value be if "Quit" selected?
        return user
    end

    # takes user attribute name as string and returns a validated user attribute
    def self.get_valid_user_attribute(attribute)
        new_attribute = nil
        while (!new_attribute) do
            case attribute
            when "password"
                new_attribute = @@prompt.ask("#{attribute}?") do |q|
                    # placeholder validation for now
                    q.validate { |input| input.length >= 6 }
                end
            when "username"
                username_available = false
                
                until username_available
                    new_attribute = @@prompt.ask("#{attribute}?") do |q|
                        # placeholder validation for now
                        q.validate { |input| input.length >= 3 }
                    end

                    user = User.find_by_username(new_attribute)
                    
                    if user
                        puts "!!! USERNAME #{new_attribute} NOT AVAILABLE ... TRY AGAIN"
                    else
                        username_available= true
                        puts "USERNAME #{new_attribute} AVAILABLE"
                    end
                end
        
            when "name"
                new_attribute = @@prompt.ask("#{attribute}?") do |q|
                    # placeholder validation for now
                    q.validate { |input| input.length >= 6 }
                end
            when "address"
                new_attribute = @@prompt.ask("#{attribute}?") do |q|
                    # placeholder validation for now
                    q.validate { |input| input.length >= 6 }
                end
            else
                puts "??? UNKNOWN USER ATTRIBUTE: #{attribute}"
            end
        end
        return new_attribute
    end

    def self.signup
        new_user = User.new
        puts "SIGN UP"
        new_user.username = Interface.get_valid_user_attribute("username")
        new_user.password = Interface.get_valid_user_attribute("password")
        new_user.name = Interface.get_valid_user_attribute("name")
        new_user.address = Interface.get_valid_user_attribute("address")
        new_user.save
        return new_user
    end

    def self.login

        puts "LOGIN"

        username = @@prompt.ask("username? ")
        user = User.where(username: username).take

        if user
            if @@test_mode
                puts "LOGIN SUCCESS"
                user.display
                return user
            else 
                password = @@prompt.mask("password? ")

                if password == user.password
                    # maybe we should a user status to show login state?
                    # user.status = "logged in"
                    puts "LOGIN SUCCESS"
                    user.display
                    return user
                else
                    puts "LOGIN FAILED"
                    return nil
                end
            end
        else
        end
    end

    # helper method for displaying and selecting one transaction from an array
    def self.select_one_transaction_from_array(transaction_array, per_page = 10)
        # pp transaction_array

        choices_array = []
        transaction_array.each do |transaction|
            hash = Hash.new
            choice_name_string = "STATUS: #{transaction.status} | QTY: #{transaction.item.quantity} | CATEGORY: #{transaction.item.category} | NAME: #{transaction.item.name}"
            hash[:name] = choice_name_string # used for prompt select
            hash[:value] = transaction # used for prompt select
            # hash[:value] = transaction.object_id
            # hash[:status] = transaction.status
            # hash[:category] = transaction.item.category
            # hash[:quantity] = transaction.item.quantity
            # hash[:item_name] = transaction.item.name
            # hash[:username] = transaction.user.username
            # hash[:user_name] = transaction.user.name
            choices_array.push(hash)
        end

        selected_transaction = nil

        selected_transaction = @@prompt.select("CHOOSE AN ITEM") do |menu|
            menu.per_page per_page
            menu.help '(Wiggle thy finger up/down and left/right to see more)'
            menu.choices choices_array
        end

        return selected_transaction
    end

    def self.donator_logo
        system("clear")
        puts""  
        puts""
        puts""
        puts""
        puts"                ██████   ██████  ███    ██  █████  ████████ ███████            ........"
        puts"                ██   ██ ██    ██ ████   ██ ██   ██    ██    ██                     ........"
        puts"          ██ ██ ██   ██ ██    ██ ██ ██  ██ ███████    ██    █████ ██ ██ ".green.blink
        puts"                ██   ██ ██    ██ ██  ██ ██ ██   ██    ██    ██                     ........"
        puts"                ██████   ██████  ██   ████ ██   ██    ██    ███████               ........"
        puts""
        puts"_________________________________________________________________________________________".colorize(:cyan)
        puts""
    end

    def self.receiver_logo
        system("clear")
        puts""
        puts"
                    ██████  ███████  ██████  ██    ██ ███████ ███████ ████████ 
                    ██   ██ ██      ██    ██ ██    ██ ██      ██         ██    
                    ██████  █████   ██    ██ ██    ██ █████   ███████    ██    
                    ██   ██ ██      ██ ▄▄ ██ ██    ██ ██           ██    ██    
                    ██   ██ ███████  ██████   ██████  ███████ ███████    ██    
                                        ▀▀                                     
                                                                   
        ".colorize(:red)
        puts"_________________________________________________________________________________________".colorize(:cyan)
    end

    def self.logo
        system("clear")

puts""  
puts""
puts""
puts""
puts"                ██████   ██████  ███    ██  █████  ████████ ███████            ........"
sleep(0.2)
puts"                ██   ██ ██    ██ ████   ██ ██   ██    ██    ██                     ........"
sleep(0.2)
puts"          ██ ██ ██   ██ ██    ██ ██ ██  ██ ███████    ██    █████ ██ ██ ".green.blink
sleep(0.2)
puts"                ██   ██ ██    ██ ██  ██ ██ ██   ██    ██    ██                     ........"
sleep(0.2)
puts"                ██████   ██████  ██   ████ ██   ██    ██    ███████               ........"
sleep(0.2)
sleep(0.4)

puts"
              ██████  ███████  ██████  ██    ██ ███████ ███████ ████████ 
              ██   ██ ██      ██    ██ ██    ██ ██      ██         ██    
              ██████  █████   ██    ██ ██    ██ █████   ███████    ██    
              ██   ██ ██      ██ ▄▄ ██ ██    ██ ██           ██    ██    
              ██   ██ ███████  ██████   ██████  ███████ ███████    ██    
                                  ▀▀                                     "
.colorize(:red)  
puts""
puts""
    end
 end




