class Transaction < ActiveRecord::Base
    belongs_to :users
    belongs_to :items

    def display
        tp self
    end

end