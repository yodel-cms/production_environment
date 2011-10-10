class UsersMigration < Migration
  def self.up(site)
    site.users.modify do |users|
      remove_field :email
      add_field :email, :alias, of: :username
      
      remove_field :first_name
      remove_field :last_name
      remove_field :name
      add_field :name, :string
      
      add_field :title, :alias, of: :name
      users.add_mixin site.pages
      
      add_many  :sites
      
      users.record_class_name = 'ProductionUser'
    end
  end
  
  def self.down(site)
  end
end
