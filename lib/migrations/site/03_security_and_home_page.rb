class SecurityAndHomePageMigration < Migration
  def self.up(site)
    # existing pages
    home = site.pages.where(path: '/').first
    sites_page = site.pages.where(path: '/sites').first
    
    # change home page to a normal page until editable production sites are ready
    home.model = site.pages
    home.page_layout = 'home'
    home.save
    
    # login page
    site.login_pages.create_model :production_login_page do |production_login_pages|
      production_login_pages.record_class_name = 'ProductionLoginPage'
    end
    
    login_page = site.production_login_pages.new
    login_page.title = 'Login'
    login_page.redirect_to = sites_page
    login_page.parent = home
    login_page.save
    
    # remove login from the nav menu
    nav = site.menus.first(name: 'nav')
    login_ex = nav.exceptions.new
    login_ex.page = login_page
    login_ex.show = false
    login_ex.save
    nav.save
    
    # logout page
    logout_page = site.logout_pages.new
    logout_page.title = 'Logout'
    logout_page.redirect_to = home
    logout_page.parent = home
    logout_page.save
    
    # prevent guest html requests; the sites and git pages implement their
    # own auth for json requests
    site.sites_pages.modify do |sites_pages|
      sites_pages.view_group = site.groups['Administrators']
      sites_pages.create_group = site.groups['Administrators']
      sites_pages.update_group = site.groups['Administrators']
      sites_pages.delete_group = site.groups['No One']
    end
    
    site.users.modify do |users|
      users.view_group = site.groups['Administrators']
      users.create_group = site.groups['Administrators']
      users.update_group = site.groups['Administrators']
      users.delete_group = site.groups['Administrators']
    end
    
    users_page = site.pages.where(path: '/users').first
    users_page.model.modify do |users_page|
      users_page.view_group = site.groups['Administrators']
      users_page.create_group = site.groups['Administrators']
      users_page.update_group = site.groups['Administrators']
      users_page.delete_group = site.groups['No One']
    end
  end
  
  def self.down(site)
    # remove the login nav menu exception
    nav = site.menus.first(name: 'nav')
    login_ex = nav.exceptions.select {|ex| ex.page.path == '/login'}
    login_ex.destroy
    nav.save
    
    # login/logout pages
    site.pages.where(path: '/login').destroy
    site.pages.where(path: '/logout').destroy
    
    # reset homepage to a redirect page
    home = site.pages.where(path: '/').first
    home.model = site.redirect_pages
    home.url = '/users'
    home.save
    
    # remove auth
    site.sites_pages.modify do |sites_pages|
      sites_pages.view_group = site.groups['Guests']
      sites_pages.create_group = site.groups['Guests']
      sites_pages.update_group = site.groups['Guests']
      sites_pages.delete_group = site.groups['Guests']
    end
    
    site.users.modify do |users|
      sites_pages.view_group = site.groups['Guests']
      sites_pages.create_group = site.groups['Guests']
      sites_pages.update_group = site.groups['Guests']
      sites_pages.delete_group = site.groups['Guests']
    end
    
    users_page = site.pages.where(path: '/users').first
    users_page.model.modify do |users_page|
      sites_pages.view_group = site.groups['Guests']
      sites_pages.create_group = site.groups['Guests']
      sites_pages.update_group = site.groups['Guests']
      sites_pages.delete_group = site.groups['Guests']
    end
  end
end
