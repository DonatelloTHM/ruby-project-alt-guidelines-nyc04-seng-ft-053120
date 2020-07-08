class Transaction < ActiveRecord::Base
    belongs_to :user
    belongs_to :item

    def display
        tp self
    end

    def self.list_all
        tp Transaction.all
    end

end