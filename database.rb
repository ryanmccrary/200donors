require 'rom-sql'

rom = ROM.container(:sql, 'postgres://localhost/200donors', username: 'postgres', password: 'postgres') do |config|
  config.default.connection.create_table(:donations) do
    primary_key :id
    column :amount, Integer, null: false
    column :paid, Boolean, null: false
  end

  config.relation(:donations) do
    schema(infer: true)
    auto_struct true
  end
end

donations = rom.relations[:donations]

(1..200).each do |donation|
  users.changeset(:create, amount: donation, paid: false).commit
end



# require 'rom'

# class Database
#   def self.initialize
#     ROM.container(:sql, 'postgres://localhost/my_db', extensions: [:pg_json]) do |config|
#       config.default.connection.create_table(:donations) do
#         primary_key :id
#         column :amount, Integer, null: false
#         column :paid, Boolean, null: false
#       end

#       config.relation(:donations) do
#         schema(infer: true)
#         auto_struct true
#       end
#     end
#   end

#   def self.seed_data
#     (1..200).each do |donation|
#       Donation.create(
#         amount: donation,
#         paid: false
#         )
#     end
#   end
# end

# class DonationRepo < ROM::Repository[:donation]
#   def query(conditions)
#     users.where(conditions).to_a
#   end

#   def by_id(id)
#     users.by_pk(id).one!
#   end

#   # ... etc
# end

# # class Donation < ROM::Repository[:donation]

# #   property :id, Serial
# #   property :amount, Integer
# #   property :paid, Boolean
# # end

# donation_repo = DonationRepo.new(rom)