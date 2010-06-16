class AccountType
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :code, String 
  
  has n, :accounts
  validates_present :name
  validates_present :code
  validates_length :name,   :minimum => 3
  validates_length :code,   :minimum => 3
  validates_is_unique :code
end
