class UsersMigration < Migration
  def self.up(site)
    site.users.modify do |users|
      users.modify_field :name, type: :string, validations: {required: {}}
      add_many  :sites
      users.add_mixin site.pages
    end
  end
  
  def self.down(site)
  end
end
