class GitPage < Page
  respond_to :get do
    with :html do
      process
    end
  end
  
  respond_to :post do
    with :html do
      process
    end
  end
  
  private
    def process
      prompt_login(:basic) and return unless logged_in?(:basic)
      
      # path is: /git/SITE_ID/GIT_PATH
      components = params['glob'].split('/')[1..-1]
      site_id = components.shift
      status(404) and return if site_id.blank?
      
      # try and load the site and ensure the user is authorised to access it
      git_site = Site.find(BSON::ObjectId.from_string(site_id))
      status(404) and return if git_site.nil?
      status(403) unless current_user.sites.include?(git_site)
      
      # reconstruct the path to match the on disk repository structure
      env['PATH_INFO'] = "/#{site_id}/.git/#{components.join('/')}"
      @_response = GitHttp::App.new({
        project_root: Yodel.config.sites_root,
        git_path: Yodel.config.git_path,
        upload_pack: true,
        receive_pack: true
      }).call(env)
      @finished = true
    end
end
