class ProductionSitesPage < RecordProxyPage
  # record proxy pages deal with site models (site.model_name). Override the methods it uses
  # to interact with these models we can edit Sites (a non site model)
  def find_record(id)
    Site.find(id)
  end
  
  def all_records
    Site.all.reject {|site| site.name == 'yodel'}
  end
  
  def construct_record
    Site.new
  end
  
  
  # get list of sites
  respond_to :get do
    with :json do
      prompt_login and return {success: false, reason: 'Login required'} unless logged_in?
      
      if params['id']
        # authorisation
        return {success: false, reason: 'Site not found'} if record.nil?
        return {success: false, reason: 'Unauthorised'} unless current_user.sites.include?(record)
        
        # users are represented by name and email address; id is used to distinguish between users
        # client side when a user's name or email is changed (the id remains constant)
        site_users = users.where(sites: requested_site.id).all.collect do |user|
          {id: user.id, name: user.name, email: user.email}
        end
        
        {success: true, domains: requested_site.domains, users: site_users, latest_revision: requested_site.latest_revision}
        
      else
        # if no site is requested, send back a list of sites available to the user
        {success: true, sites: current_user.sites.collect {|site| {id: site.id, name: site.name}}}
      end
    end
  end
  
  
  # create a site
  respond_to :post do
    with :json do
      prompt_login and return {success: false, reason: 'Login required'} unless logged_in?
      
      # create the site record
      new_site = Site.new
      new_site.root_directory = File.join(Yodel.config.sites_root, new_site.id.to_s)
      return {success: false, reason: 'Unable to create site'} unless new_site.save
      
      # initialise the root directory as a git repository
      unless `#{Yodel.config.git_path} init #{new_site.root_directory}` =~ /^Initialized empty Git repository/
        new_site.destroy
        return {success: false, reason: 'Unable to create git repository'}
      end
      
      # install the post receive hook to deploy the site on pushes, and
      # allow pushes to a non bare repository
      Dir.chdir(new_site.root_directory) do
        unless `#{Yodel.config.git_path} config 'receive.denyCurrentBranch' 'ignore'`.strip.empty?
          new_site.destroy
          return {success: false, reason: 'Unable to configure git repository'}
        end
        
        # FIXME: need error checking here
        post_receive_script = File.join(new_site.root_directory, '.git', 'hooks', 'post-receive')
        File.open(post_receive_script, 'w') do |file|
          file.write "#!/bin/bash
          cd ..
          env -i git reset --hard
          #{Yodel.config.deploy_command} deploy `basename $PWD`
          "
        end
        FileUtils.chmod(0755, post_receive_script)
      end
      
      # allow the current user to administer the new site
      current_user.sites << new_site
      unless current_user.save
        new_site.destroy
        return {success: false, reason: 'Unable to update user'}
      end
      
      {success: true, id: new_site.id}
    end
  end
  
  
  # update a site; currently only supports adding/removing users to a site
  respond_to :put do
    with :json do
      prompt_login and return {success: false, reason: 'Login required'} unless logged_in?
      
      # authorisation
      return {success: false, reason: 'Site not found'} if record.nil?
      return {success: false, reason: 'Unauthorised'} unless current_user.sites.include?(record)
      
      # find the user by id or email
      if params['user_id']
        user = site.users.find(BSON::ObjectId.from_string(params['user_id']))
      elsif params['user_email']
        user = site.users.where(email: params['user_email']).first
      else
        return {success: false, reason: 'No user id or email address provided'}
      end
      return {success: false, reason: 'Unknown user'} if user.nil?
      
      # add or remove the user from the site
      case params['action']
      when 'add'
        user.sites << record
      when 'remove'
        user.sites.delete(record)
      else
        return {success: false, reason: 'Unknown action'}
      end
      
      if user.save
        {success: true}
      else
        {success: false, reason: 'Save failed'}
      end
    end
  end
end
