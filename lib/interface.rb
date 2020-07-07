 class Interface

    @@prompt=TTY::Prompt.new

    def self.quit
        puts "QUITTING ..."
        binding.pry
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

                    binding.pry

                    user = User.find_by_username(new_attribute)
                    
                    if user
                        puts "!!! USERNAME #{new_attribute} NOT AVAILABLE ... TRY AGAIN"
                        binding.pry
                    else
                        username_available= true
                        puts "USERNAME #{new_attribute} AVAILABLE"
                        binding.pry
                    end
                end

                binding.pry
        
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
        binding.pry
        return new_attribute
    end

    def self.signup
        new_user = User.new
        puts "SIGN UP"
        new_user.username = Interface.get_valid_user_attribute("username")
        new_user.password = Interface.get_valid_user_attribute("password")
        new_user.name = Interface.get_valid_user_attribute("name")
        new_user.address = Interface.get_valid_user_attribute("address")
        binding.pry
        new_user.save
        return new_user
    end

    def self.login

        puts "LOGIN"

        username = @@prompt.ask("username? ")
        user = User.where(username: username).take

        if user
            password = @@prompt.mask("password? ")
            if password == user.password
                # maybe we should a user status to show login state?
                # user.status = "logged in"
                puts "LOGIN SUCCESS"
                user.display
                return user
            end
        else
            puts "LOGIN FAILED"
            return nil
        end
    end
 end
