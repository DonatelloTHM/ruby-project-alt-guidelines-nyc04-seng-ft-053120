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

tracy = User.create(
    username: "threecee",
    password: "111111",
    name: "tracy",
    address: "brooklyn"
)

joe = User.create(
    username: "joe",
    password: "111111",
    name: "joe blow",
    address: "who knows"
)

17.times do

    donated_item = Item.create(
        quantity: Faker::Number.between(from: 1, to: 5),
        description: Faker::Vehicle.car_type,
        name: Faker::Vehicle.make_and_model,
        category: "Cars"
    )

    case rand(2)
    when 0
        donor = tracy
    when 1
        donor = joe
    else
        donor = User.create(
            username: Faker::Superhero.name.gsub(/\s+/, ""),
            password: Faker::Kpop.i_groups.gsub(/\s+/, ""),
            name: Faker::Name.name,
            address: Faker::Address.full_address
        )
    end

    donatiom = Transaction.create(
        donor_id: donor.id,
        quantity: donated_item.quantity,
        item_id: donated_item.id,
        status: "Added",
        kind: "Donation"
    )

    requested_item = Item.create(
        quantity: Faker::Number.between(from: 1, to: 10),
        description: Faker::Appliance.brand,
        name: Faker::Appliance.equipment,
        category: "Appliances"
    )

    case rand(2)
    when 0
        requester = tracy
    when 1
        requester = joe
    else
        requester = User.create(
            username: Faker::Superhero.name.gsub(/\s+/, ""),
            password: Faker::Kpop.i_groups.gsub(/\s+/, ""),
            name: Faker::Name.name,
            address: Faker::Address.full_address
        )
    end
    
    request = Transaction.create(
        requester_id: requester.id,
        quantity: requested_item.quantity,
        item_id: requested_item.id,
        status: "Open",
        kind: "Donation"
    )


end

