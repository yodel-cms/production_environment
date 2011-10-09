class SitesPage < RecordProxyPage
  # record proxy pages deal with site models (site.model_name). Override the methods it uses
  # to interact with these models we can edit Sites (a non site model)
  def record
    @record ||= Site.find(BSON::ObjectId.from_string(params['id']))
  end
  
  def records
    @records ||= Site.all
  end
  
  # get list of sites
  respond_to :get do
    with :json do
    end
  end
  
  # create a site
  respond_to :post do
    with :html do
    end
  end
end
