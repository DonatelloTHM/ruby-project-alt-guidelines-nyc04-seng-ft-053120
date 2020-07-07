 class Interface

    @@prompt=TTY::Prompt.new

    def self.quit
        puts "QUITTING ..."
        binding.pry
    end

    def self.login_signup

        puts "LOGIN / SIGN UP"

        @@prompt.select("",active_color: :green) do |w|
            w.choice "          Login", -> {login}
            w.choice "          Sign Up".cyan, -> {signup}
            w.choice "          Quit".red, -> {quit}  #1
        end

        binding.pry
    end

    def self.signup
        puts "SIGN UP"
        binding.pry
    end

    # create_table "users", force: :cascade do |t|
    #     t.string "username"
    #     t.string "password"
    #     t.string "name"
    #     t.string "address"
    #   end
    
    def self.login
        puts "LOGIN"
        username = @@prompt.ask("username? ")
        user = User.where(username: username).take
        if user
            password = @@prompt.ask("password? ")
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
