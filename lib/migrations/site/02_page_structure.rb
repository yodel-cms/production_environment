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
    # work around eigenmodel/record_class_name bug
    site.record_proxy_pages.create_model :sites_page do |sites_pages|
      sites_pages.record_class_name = 'ProductionSitesPage'
    end
    sites = site.sites_pages.new
    sites.title = 'Sites'
    sites.parent = home
    sites.page_layout = 'sites'
    sites.show_record_layout = 'site'
    sites.save
    
    # users
    users = site.pages.new
    users.title = 'Users'
    users.parent = home
    users.page_layout = 'users'
    users.save
    users.create_eigenmodel
    users.model.default_child_model = site.users
    users.model.save
    
    # git
    site.glob_pages.create_model :git_page do |git_pages|
      git_pages.record_class_name = 'GitPage'
    end
    git = site.git_pages.new
    git.title = "git"
    git.parent = home
    git.save
    
    # menu
    nav = site.menus.new
    nav.name = 'nav'
    nav.root = home
    ge = nav.exceptions.new
    ge.page = git
    ge.show = false
    ge.save
    nav.save
  end
  
  def self.down(site)
    site.pages.all.each(&:destroy)
  end
end
