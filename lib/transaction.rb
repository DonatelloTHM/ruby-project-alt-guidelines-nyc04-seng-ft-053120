class Transaction < ActiveRecord::Base
    belongs_to :users
    belongs_to :items

    def display
        pp self
    end

end