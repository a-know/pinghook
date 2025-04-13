class Block < ApplicationRecord
  belongs_to :blocker
  belongs_to :blocked
end
