class PageStructureMigration < Migration
  def self.up(site)
    # remove the default home page
    home = site.pages.where(path: '/').first
    home.destroy
    
    # home redirects to users
    home = site.redirect_pages.new
    home.title = 'Home'
    home.url = '/users'
    home.save
    
    # sites
    sites = site.record_proxy_pages.new
    sites.title = 'Sites'
    sites.parent = home
    sites.show_record_layout = 'site'
    sites.save
    sites.create_eigenmodel
    sites.model.record_class_name = 'SitesPage'
    sites.model.save
    
    # users
    users = site.pages.new
    users.title = 'Users'
    users.parent = home
    users.save
    users.create_eigenmodel
    users.model.default_child_model = site.users
    users.model.save
    
    # menu
    nav = site.menus.new
    nav.name = 'nav'
    nav.root = home
    nav.save
  end
  
  def self.down(site)
    site.pages.all.each(&:destroy)
  end
end
