User.destroy_all
Item.destroy_all
Transaction.destroy_all

# 20.times do
#     User.create(
#         username: Faker::Superhero.name.gsub(/\s+/, ""),
#         password: Faker::Kpop.i_groups.gsub(/\s+/, ""),
#         name: Faker::Name.name,
#         address: Faker::Address.full_address
#     )
# end

User.create(
    username: "threecee",
    password: "111111",
    name: "tracy",
    address: "brooklyn"
)

User.create(
    username: "joe",
    password: "111111",
    name: "joe blow",
    address: "who knows"
)
