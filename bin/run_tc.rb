require_relative '../config/environment'
# user = User.find(47)

# Login
# If user is new, create and login new user
# If user exists, login user
user = nil

# binding.pry

while (!user) do
    user = Interface.login_signup
end

User.user_menu(user)
