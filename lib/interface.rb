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
    # options = {:first_name => "Justin", :last_name => "Weiss"}
    def self.select_one_transaction_from_array(transaction_array:, per_page: 10, choice: false)
        # pp transaction_array

        choices_array = []
        transaction_array.each do |transaction|
            hash = Hash.new
            choice_name_string = "STATUS: #{transaction.status} | QTY: #{transaction.item.quantity} | CATEGORY: #{transaction.item.category} | NAME: #{transaction.item.name}"
            hash[:name] = choice_name_string # used for prompt select
            hash[:value] = transaction # used for prompt select

            choices_array.push(hash)
        end

        # if transaction is actually a predefined choice, just push into choice array
        if choice
            choices_array.push(choice)
        end

        selected_transaction = nil

        selected_transaction = @@prompt.select("CHOOSE AN ITEM") do |menu|
            menu.per_page per_page
            menu.help '(Wiggle thy finger up/down and left/right to see more)'
            menu.choices choices_array
        end

        return selected_transaction
    end


#---------------------------------INTERFACE FLOW--------------------------
# login_register=prompt.select("".colorize(:color => :black, :background => :light_green), ["               Login                ","              Register             ","               Quit               ".colorize(:red)])



    def self.first_menu
        Interface.logo
        puts "          Select your option         ".colorize(:color => :black, :background => :light_green)+"                          ".colorize(:background => :cyan)+"          ".colorize(:background => :light_blue)
        puts""
        login_register=@@prompt.select("".colorize(:color => :black, :background => :light_green), ["               Login                ","              Register             ","               Quit               ".colorize(:red)])
        if(login_register=="               Login                ")
            self.login
        elsif(login_register=="              Register             ")
            self.register
        else
            self.quit     #build this method
        end
    end


    def self.login
        self.logo_no_animation
        self.login_screen_banner
        puts""
        puts""
        puts "                     "+"      What's your Username?     ".colorize(:background=>:red)
        username=@@prompt.ask("                     "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        user = User.where(username: username).take
        if user
           self.check_password(user)
        else
            self.logo_no_animation
            self.login_screen_banner
           puts"       You typed '#{username}', which can't be found anywhere in our userbase         ".colorize(:background=>:red)
            rollback= @@prompt.select("     ",active_color: :green) do |w|
                    w.choice "          Try Again", -> {self.login}
                    w.choice "          Register", -> {self.register}
                    w.choice "          Quit".red, -> {Interface.quit}
            end
        end
    end

    def self.check_password(user)
        puts""
        puts "                     "+"      What's your Password?     ".colorize(:background=>:red)
            password = @@prompt.mask("                     "+" # ".colorize(:color=>:red,:background=>:white),required: true)
            if password == user.password
                self.animation(2)
                self.welcome_user_animation(user)
                User.user_menu(user)
            else    
                self.logo_no_animation
                self.login_screen_banner
               puts"                            WRONG PASSWORD                            ".colorize(:background=>:red)
                rollback= @@prompt.select("     ",active_color: :green) do |w|
                        w.choice "          Try Again", -> {self.password_try_again(user)}
                        w.choice "          Register", -> {self.register}
                        w.choice "          I have another account", -> {self.login}
                        w.choice "          Quit".red, -> {Interface.quit}
                end
            end
    end

    def self.password_try_again(user)
        self.logo_no_animation
        self.login_screen_banner
        puts""
        self.check_password(user)
    end


    def self.register
      self.logo_no_animation
      self.signup_screen_banner
      puts""
      puts "                        "+"         Username         ".colorize(:background=>:red)
        username=@@prompt.ask("                        "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true) do |q|
            q.validate{|input| input.length >= 3}
            q.messages[:valid?] = 'Username should be 3 or more characters long'
        end
        user = User.where(username: username).take
        if user
                self.logo_no_animation
                self.signup_screen_banner
                puts"       User '#{username}' already exists, try another one.      ".colorize(:background=>:red)
                rollback= @@prompt.select("     ",active_color: :green) do |w|
                        w.choice "          Try Again", -> {self.register}
                        w.choice "          Login Screen", -> {self.login}
                        w.choice "          Quit".red, -> {Interface.quit}
                end
        else
          puts""
          puts"       You chose  '#{username}' as your username, want to continue?      ".colorize(:background=>:green)
          rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Yes"
            w.choice "          No, I want to change it", -> {self.register}
            w.choice "          Login Screen", -> {self.login}
            w.choice "          Quit".red, -> {Interface.quit}  
          end
        end
        password=self.register_password
        name=self.name_of_user
        full_address=self.full_address
        new_user=User.create(username:username,password:password,name:name,address:full_address)
        self.animation(1)
        self.welcome_user_animation(new_user)
        User.user_menu(new_user)
    end

    def self.register_password
      password1=""
      loop do
      self.logo_no_animation
      self.signup_screen_banner
      puts""
      puts "                        "+"         Password         ".colorize(:background=>:red)
        password1=@@prompt.mask("                        "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true) do |q|
            q.validate{|input| input.length >= 6}
            q.messages[:valid?] = 'Password should be 6 or more characters long'
        end
        puts""
        puts "                        "+"     Retype Password      ".colorize(:background=>:red)
        password2=@@prompt.mask("                        "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true) do |q|
        end
        break if password1 == password2
          puts""
          puts"         "+"       Your password doesn't match , Try again!      ".colorize(:background=>:blue)
          sleep(2)
      end 
       puts""
        puts"         "+"         Are you happy with your password?       ".colorize(:background=>:green)
          rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Yes"
            w.choice "          No, I want to change it", -> {self.register_password}
            w.choice "          Login Screen", -> {self.login}
            w.choice "          Quit".red, -> {Interface.quit}  
          end
          password1
        
    end
    
    def self.name_of_user

      self.logo_no_animation
      self.signup_screen_banner
      puts""
      puts "                        "+"         Name         ".colorize(:background=>:red)
        name=@@prompt.ask("                        "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        puts""
        puts"         "+"         Is #{name} your name?       ".colorize(:background=>:green)
          rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Yes"
            w.choice "          No, I want to change it", -> {self.name_of_user}
            w.choice "          Login Screen", -> {self.login}
            w.choice "          Quit".red, -> {Interface.quit}  
          end
          name
    end

    def self.full_address

      self.logo_no_animation
      self.signup_screen_banner
      puts""
      puts "                        "+"        Type your full address       ".colorize(:background=>:red)
        full_address=@@prompt.ask("                        "+" ? ".colorize(:color=>:red,:background=>:light_white),required: true)
        puts""
        puts"         "+"   Your address is '#{full_address}' , correct?  ".colorize(:background=>:green)
          rollback= @@prompt.select("     ",active_color: :green) do |w|
            w.choice "          Yes"
            w.choice "          No, I want to change it", -> {self.full_address}
            w.choice "          Login Screen", -> {self.login}
            w.choice "          Quit".red, -> {Interface.quit}  
          end
        full_address
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

    def self.logo_no_animation
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












    def self.animation(n_times)
        animacioni=[]
        frame_0="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo/so/-`                                            
                                                 .+ydmmmmmyNmmmdh+.                                         
                                               .sdmmmNNNNmyNNNNmmmms.                                       
                                              `hmmNNNNNNdyodNNNNNNNmd:                                      
                                                .+hNNy:      -sNNmdddm/                                     
                                                   `.          .dNNNNmd`                                    
                                                                oNNNmmd/                                    
                                                                oNNNmmd/                                    
                                                   `.          .dNNNNmd.                                    
                                                -odNNs-      -sNNdddmm+                                     
                                              .dmmNNNNNNdsydNNNNNNNmh:                                      
                                               .smmmmNNNNhNNNNNmmmmy-                                       
                                                 .+hdmmmNhmNmmmdho-                                         
                                                    `:+os+sso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_1="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo`oo/-`                                            
                                                 .+ydmmmmm-mmmmdh+.                                         
                                               .sdmmmNNNNm:NNNNmmmms.                                       
                                              `hmmNNNNNNdy:dNNNNNNNmm/                                      
                                                .+hNNy:      -sNNNmddh/                                     
                                                   `.          -dmNNNmd`                                    
                                                                oNNNmmd/                                    
                                                                oNNNmmd/                                    
                                                  `:-          .NNNNNmd.                                    
                                              `:odNMNs-      -sNmmmNmm+                                     
                                              :dmmNNNNNNdoydNNNNNNmdh/                                      
                                               .smmmmNNNNdNNNNNmmmmy-                                       
                                                 .+hdmmmmhNNmmmdho-                                         
                                                    `:+osoyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_2="
        
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                                                                                                                               
                                                    `-/+oo `//-`                                            
                                                 .+ydmmmmm -mmmdh+.                                         
                                               .sdmmmNNNNm oNNNmmmms.                                       
                                              `hmmNNNNNNdy sNNNNNNNmm/                                      
                                                .+hNNy:      -sNNNNNmd:                                     
                                                   `.          -dmmmmmd`                                    
                                                                oNNNmmd/                                    
                                                                oNNNmmd/                                    
                                               `.:oy:          -NMNNNmd.                                    
                                             .ydmNNMNs-      -smmNNNmm+                                     
                                              /dmmNNNNNNyyydNNNNNmddd+                                      
                                               .smmmmNNNdNNNNNNmmmms.                                       
                                                 .+hdmmmdNNNmmmdho-                                         
                                                    `:++oyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_3="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo   `-`                                            
                                                 .+ydmmmmm   oddh+.                                         
                                               .sdmmmNNNNm  -dNmmmms.                                       
                                              `hmmNNNNNNdy  yNNNNNNmm/                                      
                                                .+hNNy:      -sNNNNNmm/                                     
                                                   `.          -NNNmmdh`                                    
                                                                +mmmmmd/                                    
                                               ``.-.            oNNNmmd/                                    
                                             oydmNNN:          -NMNNNmd.                                    
                                             /mmNNNMNs-      -omNNNNmm+                                     
                                              /dmmNNNNNdhhydNNNmmmNmm+                                      
                                               .smmmmNmmNNNNNNNmmdhs-                                       
                                                 .+hdddmNNNNmmmdho.                                         
                                                    `-/osyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_4="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm     .++.                                         
                                               .sdmmmNNNNm    -ymmms.                                       
                                              `hmmNNNNNNdy   -hNNNNmm/                                      
                                                .+hNNy:      .sNNNNNmm/                                     
                                                   `.          -NMNNNmd`                                    
                                            `...```             +NNmmdd:                                    
                                            -hddmmmo            +NNmmdd:                                    
                                            `dmmNNNN:          -NMNNNmd.                                    
                                             /mmNNNMNs-      .sNMNNNmm+                                     
                                              /dmmNNNmmNdhyhmmmNNNNmm+                                      
                                               .smmmdmNNNNNNNNmdmmmy-                                       
                                                 .+ydmmmNNNNmmmdy+-                                         
                                                    `:+osyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_5="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm                                                  
                                               .sdmmmNNNNm       :ss.                                       
                                              `hmmNNNNNNdy     .smNmm/                                      
                                                .+hNNy:       .mNNNNmm/                                     
                                             ::.`  `.          -NMNNNmd`                                    
                                            -dmmmmd/            oNNNmmd/                                    
                                            :dmmNNNs            +mNmmmd/                                    
                                            `dmmNNNN:          -NNNmmdh`                                    
                                             /mmNNNNNo-      -sNMNNNmm+                                     
                                              /dmmmmmNNNdhyhdNNNNNNmm+                                      
                                               .shdmmNNNNNNNmmNmmmmy-                                       
                                                 .+hdmmmNNNNmdddho-                                         
                                                    `:+osyyso/-.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_6="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm                                                  
                                               .sdmmmNNNNm          `                                       
                                              `hmmNNNNNNdy       `/hd/                                      
                                             .-`-+hNNy:        .smNNmm/                                     
                                            `dmmhs/-.          -NMNNmmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNN:          -dmmmmmd.                                    
                                             /mmNNNmms-      -sNMNNNmd/                                     
                                              /dddmNNNNNdhyyNNNNNNNmm+                                      
                                               `smmmmNNNNNNdNNNmmmmy-                                       
                                                 .+hdmmmNNNdmmmdho-                                         
                                                    `:+osyyo++:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_7="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm                                                  
                                               .sdmmmNNNNm                                                  
                                              `hmmNNNNNNdy         `//                                      
                                             :yo+ohNNy:         `/hmmm/                                     
                                            `dmmNNds.          `NMNNmmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNN-          .dmNNNmd.                                    
                                             /mmNmmmNs-      -sNNNmddd/                                     
                                              :hdmNNNNNNdhodNNNNNNmmm/                                      
                                               .smmmmNNNNNdNNNNmmmmy-                                       
                                                 .+hdmmmNNhmmmmdho-                                         
                                                    `:+osyooo+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_8="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm                                                  
                                               .sdmmmNNNNm                                                  
                                              .hmmNNNNNNdy          `.                                      
                                             :mdhhdNNy:          .+ymm/                                     
                                            `dmmNNNd-           hMNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNm.          .dNNNNmd.                                    
                                             /mmdddNNs-      -sNNmdddm+                                     
                                              -hmNNNNNNNdyodNNNNNNNmd:                                      
                                               .smmmmNNNNNhNNNNmmmmy-                                       
                                                 .+hdmmmNNhNmmmdho-                                         
                                                    `:+oss+so+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_9="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo                                                  
                                                 .+ydmmmmm                                                  
                                               .sdmmmNNNNm                                                  
                                              -hmmNNNNNNdy           .                                      
                                             :mddddNNy:          `/sdm/                                     
                                            `dmmNNNd-           hNNNmmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNd.          .dNNNNmd.                                    
                                             /mmdddNNs-      -sNNdddmm+                                     
                                              -hmNNNNNNNdyodNNNNNNNmh:                                      
                                               .smmmmNNNNmdNNNNmmmmy-                                       
                                                 .+hdmmmNmhNmmmdho-                                         
                                                    `:+oso+so+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_10="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+os`                                                 
                                                 .+ydmmmmm`                                                 
                                               .sdmmmNNNNN`                                                 
                                              -hmmNNNNNNdh           .                                      
                                             :mmdddNNy:          `/sdm/                                     
                                            `dmmNNNm-           hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNd-          .hNNNNmd.                                    
                                             /mdddmNNs-      -sNNhhhmm+                                     
                                              -dmNNNNNNNdsydNNNNNNNmy-                                      
                                               .smmmmNNNNhNNNNNmmmmy-                                       
                                                 .+hdmmmNhmNmmmdho-                                         
                                                    `:+os+sso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_11="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+os+                                                 
                                                 .+ydmmmmNs                                                 
                                               .sdmmmNNNNNo                                                 
                                              :hdmNNNNNNdh:          .                                      
                                             :mmmmmmNy:          `/sdm/                                     
                                            `dmmNNMN-           hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNmd-          `hNNNNmd.                                    
                                             :dddmNMNs-      -sNhooymm+                                     
                                              :dmNNNNNNNdohdNNNNNNmh+.                                      
                                               .smmmmNNNNdNNNNNmmmmy-                                       
                                                 .+hdmmmmhNNmmmdho-                                         
                                                    `:+osoyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_12="  
        
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+osso`                                               
                                                 .+ydmmmmNNh`                                               
                                               `odmmmNNNNNN+                                                
                                              :dddmNNNNNdhh.         .                                      
                                             :mmNNNmmy:          `/sdm/                                     
                                            `dmmNNMN:           hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmmmmm:           hNNNNmd.                                    
                                             :dmmNNMNs-      -sh/./ymm+                                     
                                              /dmNNNNNNNyyhdNNNNNdo. .                                      
                                               .smmmmNNNdNNNNNNmmmms`                                       
                                                 .+hdmmmdNNNmmmdho-                                         
                                                    `:++oyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_13="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+ossso:`                                             
                                                 `+ydmmmmNNNms`                                             
                                               .ohdmmNNNNNNNd-                                              
                                              :dmmmmmNNNdhhd/        .                                      
                                             :mmNNNNNs:          `/sdm/                                     
                                            `dmmNNMN:           hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmmNmo            oNNNNmd/                                    
                                            `hdmmNNN:           hNNNNmd.                                    
                                             /mmNNNMNs-      -/` `/ymm+                                     
                                              /dmNNNNNNdhhhdNNNd+`   .                                      
                                               .smmmmNmmNNNNNNNmmh/                                         
                                                 .+hdddmNNNNmmmdho.                                         
                                                    `-/osyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_14="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+ossso/-`                                            
                                                 .+sdmmmmNNNmmmh/                                           
                                               .sdmmdmNNNNNNNNd+`                                           
                                              :dmmNNNmmNdhhdNd/      .                                      
                                             :mmNNNNNy-      `   `/sdm/                                     
                                            `dmmNNMN:           hNNNmmd`                                    
                                            -ddmmNNs            oNNNmmd/                                    
                                            -ddmmNNs            oNNNNmd/                                    
                                            `dmmNNNN:           hNNNNmd.                                    
                                             /mmNNNMNs-      `   `/ymm+                                     
                                              /dmNNNNmmNdhhdNd:      .                                      
                                               .smmmdmNNNNNNNNd+`                                           
                                                 .+ydmmmNNNNmmmh+                                           
                                                    `:+osyyso+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_15="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-:+osss+/-`                                            
                                                 .+ydddmmNNNmmmdh+.                                         
                                               .sdmmmNmmNNNNNNNmmh/                                         
                                              :dmmNNNNNddhhdNNNmo.   .                                      
                                             :mmNNNNNy:      -+. `/sdm/                                     
                                             hdmmNNN:           hNNNmmd`                                    
                                            -dmmmmmo            oNNNmmd/                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            `dmmNNNN:           hNNNNmd.                                    
                                             /mmNNNNNo-          `/ymm+                                     
                                              /dmNmmmNNNdhhh/        .                                      
                                               .sddmmNNNNNNNd-                                              
                                                 .+hdmmmNNNNms`                                             
                                                    `:+osyyso/`                                             
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_16="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/++ssso/-`                                            
                                                 .+ydmmmdNNNmmmdh+.                                         
                                               .sdmmmNNNdNNNNNNmmmms`                                       
                                              :dmmNNNNNNhhhdNNNNNmo- .                                      
                                             -dmNNNNNy:      -sh/./sdm/                                     
                                            `dmmmmmm:           hNNNNmd`                                    
                                            -dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNN:           hNNNNmd.                                    
                                             /mmNNNmms-          `/ymm+                                     
                                              /dddmNNNNNdhy.         .                                      
                                               `smmmmNNNNNN+                                                
                                                 .+hdmmmNNNy`                                               
                                                    `:+osyyo`                                               
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_17="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+o+sso/-`                                            
                                                 .+ydmmmmhNNmmmdh+.                                         
                                               .sdmmmNNNNdNNNNNmmmms.                                       
                                              :dmmNNNNNNdshdNNNNNNmh+.                                      
                                             :hddmNNNy:      -sNdsosdm/                                     
                                            `dmmNNmm:          `hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNN-           hNNNNmd.                                    
                                             /mmNmmmNs-          `/ymm+                                     
                                              :hdmNNNNNNdh:          .                                      
                                               .smmmmNNNNNo                                                 
                                                 .+hdmmmNNs                                                 
                                                    `:+osy+                                                 
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_18="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+o+oso/-`                                            
                                                 .+ydmmmmhmNmmmdh+.                                         
                                               .sdmmmNNNNhNNNNNmmmms.                                       
                                              -dmmNNNNNNdsydNNNNNNNmh-                                      
                                             :mdddmNNy:      -sNNdhhdm/                                     
                                            `dmmNNNd-          .hNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNm.           hNNNNmd.                                    
                                             /mmdddNNs-          `/ymm+                                     
                                              -hmNNNNNNNdy           .                                      
                                               .smmmmNNNNN`                                                 
                                                 .+hdmmmNN`                                                 
                                                    `:+oss`                                                 
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_19="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo+so/-`                                            
                                                 .+ydmmmmmhNmmmdh+.                                         
                                               .sdmmmNNNNmhNNNNmmmms.                                       
                                              -hmmNNNNNNdysdNNNNNNNmd-                                      
                                             :mddddNNy:      -sNNddddm/                                     
                                            `dmmNNNd-          .dNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNd.           hNNNNmd.                                    
                                             /mmdddNNs-          `/ymm+                                     
                                              -hmNNNNNNNdy           .                                      
                                               .smmmmNNNNm                                                  
                                                 .+hdmmmNm                                                  
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_20="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+os+so/-`                                            
                                                 .+ydmmmmNhNmmmdh+.                                         
                                               .sdmmmNNNNNhNNNNmmmms.                                       
                                              -hmmNNNNNNdhsdNNNNNNNmd:                                      
                                             :mmdddNNy:      -sNMmdddm/                                     
                                            `dmmNNNm-          .dNNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNNd.           dMNNNmd.                                    
                                             /mdhhdNNs-          .+hmm+                                     
                                              -hmNNNNNNNdy          `-                                      
                                               .smmmmNNNNm                                                  
                                                 .+hdmmmNm                                                  
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_21="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+os+oo/-`                                            
                                                 .+ydmmmmNhmmmmdh+.                                         
                                               .sdmmmNNNNNdNNNNmmmms.                                       
                                              :hdmNNNNNNdhsdNNNNNNNmm/                                      
                                             :mmmmmmNy:      -sNMNmddh/                                     
                                            `dmmNNNN-          -dmNNNmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmNNds.          `mMNNNmd.                                    
                                             :hs+ohNNs-         .+hNmm+                                     
                                              `hmNNNNNNNdy         .//                                      
                                               .smmmmNNNNm                                                  
                                                 .+hdmmmNm                                                  
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_22="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+osso+/-`                                            
                                                 .+ydmmmmNNdmmmdh+.                                         
                                               `odmmmNNNNNNdNNNmmmms.                                       
                                              :dddmNNNNNdhhyNNNNNNNmm/                                      
                                             :mmNNNmmy:      -sNMNNNmd:                                     
                                            `dmmNNNN:          -dmmmmmd`                                    
                                            :dmmNNNs            oNNNmmd/                                    
                                            :dmmNNNs            oNNNNmd/                                    
                                            `dmmdy+:.          -NMNNNmd.                                    
                                             .-`.+hNNs-        -sNNNmm+                                     
                                              `hmNNNNNNNdy       `+hd+                                      
                                               .smmmmNNNNm          `                                       
                                                 .+hdmmmNm                                                  
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_23="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+ossso/-`                                            
                                                 `+ydmmmmNNNmdddh+.                                         
                                               .ohdmmNNNNNNNmmNmmmms.                                       
                                              :dmmmmmNNNdhhddNNNNNNmm/                                      
                                             :mmNNNNNs:      -sNMNNNmm/                                     
                                            `dmmNNNN:          -NNNmmdh`                                    
                                            :dmmNNNs            +mmmmmd/                                    
                                            :dmmmmd/            oNNNNmd/                                    
                                            `/:-.` `.          -NMNNNmd.                                    
                                                .+hNNs-       .mNNNNmm+                                     
                                              `hmNNNNNNNdy     .smNmm+                                      
                                               .smmmmNNNNm       :ys-                                       
                                                 .+hdmmmNm                                                  
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_24="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+ossso/-`                                            
                                                 ./sdmmmmNNNmmmdy+.                                         
                                               .sdmmdmNNNNNNNNmdmmms.                                       
                                              :dmmNNNmmNdhhdNmmNNNNmm/                                      
                                             :mmNNNNNy-      -sNMNNNmm/                                     
                                            `dmmNNNN:          -NMNNNmd`                                    
                                            -hddmmNs            +NNmmdd:                                    
                                            `......`            +NNmmdd:                                    
                                                   `.          -NMNNNmd.                                    
                                                .+hNNs-      .sNMNNNmm+                                     
                                              `hmNNNNNNNdy   -dNNNNmm+                                      
                                               .smmmmNNNNm    -ymmmy-                                       
                                                 .+hdmmmNm     -o+-                                         
                                                    `:+oss                                                  
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_25="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-:+ossso/-`                                            
                                                 .+ydddmmNNNmmmdh+.                                         
                                               .sdmmmNmmNNNNNNNmmdhs.                                       
                                              :dmmNNNNNddhhdNNNmmmmmm/                                      
                                             :mmNNNNNy:      -omNNNNmm/                                     
                                             shdmNNN:          -NMNNNmd`                                    
                                               `..--            oNNNNmd/                                    
                                                                +mmmmmd/                                    
                                                   `.          -NNNmmdh`                                    
                                                .+hNNs-      -sNMNNNmm+                                     
                                              `hmNNNNNNNdy  sNNNNNNmm+                                      
                                               .smmmmNNNNm  -dNmmmmy-                                       
                                                 .+hdmmmNm   oddho-                                         
                                                    `:+oss   `-.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_26="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/++ssso/-`                                            
                                                 .+ydmmmdNNNmmmdh+.                                         
                                               .sdmmmNNNdNNNNNNmmmms.                                       
                                              :dmmNNNNNNhhhdNNNNNmddd/                                      
                                             .ydNNNNNy:      -smmNNNmm/                                     
                                               `-/sh:          -NMNNNmd`                                    
                                                                oNNNNmd/                                    
                                                                oNNNNmd/                                    
                                                   `.          -dmmmmmd.                                    
                                                .+hNNs-      -sNMNNNmd/                                     
                                              `hmNNNNNNNdy sNNNNNNNmm+                                      
                                               .smmmmNNNNm oNNNmmmmy-                                       
                                                 .+hdmmmNm -mmmdho-                                         
                                                    `:+oss `++:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_27="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+o+ss+/-`                                            
                                                 .+ydmmmmhNNmmmdh+.                                         
                                               .sdmmmNNNNdNNNNNmmmms.                                       
                                              :dmmNNNNNNdshdNNNNNNmdh/                                      
                                              `/sdNNNy:      -sNmmmmmm/                                     
                                                  ./-          .NMNNNmd`                                    
                                                                oNNNNmd/                                    
                                                                oMNNNmd/                                    
                                                   `.          .dmNNNmd.                                    
                                                .+hNNs-      -sNMNmddd/                                     
                                              `hmNNNNNNNdy:dNNNNNNNmm/                                      
                                               .smmmmNNNNm:NNNNmmmmy-                                       
                                                 .+hdmmmNm-mmmmdho-                                         
                                                    `:+oss`oo+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_28="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+o+oso/-`                                            
                                                 .+ydmmmmhmNmmmdh+.                                         
                                               .sdmmmNNNNhNNNNNmmmms.                                       
                                              .dmmNNNNNNdsydNNNNNNNmh:                                      
                                               `:odNNy:      -sNNdddmm/                                     
                                                   .-          .dNNNNmd`                                    
                                                                oNNNNmd/                                    
                                                                +NNNNmd/                                    
                                                   `.          .dNNNNmd.                                    
                                                .+hNNs-      -sNNmdddm+                                     
                                              `hmNNNNNNNdyodNNNNNNNmd:                                      
                                               .smmmmNNNNmyNNNNmmmmy-                                       
                                                 .+hdmmmNmyNmmmdho-                                         
                                                    `:+oss/so+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        frame_29="
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                    `-/+oo+so/-`                                            
                                                 .+ydmmmmmhNmmmdh+.                                         
                                               .sdmmmNNNNmhNNNNmmmms.                                       
                                              `hmmNNNNNNdysdNNNNNNNmd-                                      
                                                .+hNNy:      -sNNddddm/                                     
                                                   `.          .dNNNNmd`                                    
                                                                oNNNNmd/                                    
                                                                +NNNNmd/                                    
                                                   `.          .dNNNNmd.                                    
                                                .+hNNs-      -sNNdddmm+                                     
                                              `hmNNNNNNNdyodNNNNNNNmh:                                      
                                               .smmmmNNNNmhNNNNmmmmy-                                       
                                                 .+hdmmmNmhNmmmdho-                                         
                                                    `:+oss+so+:.                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                            
                                                                                                    "
        
        a=[:cyan,:light_green]        
        system("clear")                                                                                           
        animacioni=[frame_0,frame_1,frame_2,frame_3,frame_4,frame_5,frame_6,frame_7,frame_8,frame_9,frame_10,frame_11,frame_12,frame_13,frame_14,frame_15,frame_16,frame_17,frame_18,frame_19,frame_20,frame_21,frame_22,frame_23,frame_24,frame_25,frame_26,frame_27,frame_28,frame_29]
        info=["Communicating with the server","Sending back the acquired data "]
        b=0
        n_times.times do
    
            i = 1
            while i < 3
                animacioni.each do |frame|
                    puts frame.colorize(a[b])
                    puts "            "+"                                #{+info[b]}                             ".colorize(:color => :white, :background => :blue)
                    sleep(0.1)
                    system("clear")
                    i += 1
                end
                system("clear")
            end
            b+=1
        end
        end


        def self.welcome_user_animation(user)
            ngjyra=[:cyan,:light_green,:blue,:magenta,:red,:yellow,:green,:blue,:light_blue,:light_green]
                ffr=0
                4.times do
                puts ""
                puts ""
                a=Artii::Base.new :font => 'slant'
                puts a.asciify("  Welcome")
                ds=Artii::Base.new :font => 'slant'
                puts""
                puts ds.asciify("     "+user.name).colorize(ngjyra[ffr])
                sleep (0.3)
                system("clear")
                ffr+=1
                end
        end

        def self.login_screen_banner
        # puts "                          "+"                       ".colorize(:color => :white,:background => :green)
        puts "                          ".colorize(:color => :black, :background => :light_white)+"     LOGIN SCREEN      ".colorize(:color => :black,:background => :green)+"                          ".colorize(:background => :light_white)
        end

        def self.signup_screen_banner
          # puts "                          "+"                       ".colorize(:color => :white,:background => :green)
          puts "                          ".colorize(:color => :black, :background => :light_white)+"     SIGNUP SCREEN     ".colorize(:color => :black,:background => :green)+"                          ".colorize(:background => :light_white)
          end
end




