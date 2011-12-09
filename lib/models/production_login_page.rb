class ProductionLoginPage < LoginPage
  respond_to :post do
    with :html do
      # production user overrides passwords_match? to compare passwords without hashing the
      # password being tested. Yodel development clients store the password as a hash so
      # there's no need to hash the password again server side. For html clients logging in,
      # passwords will be in plain text; the password is hashed here, then control passed up
      # for login to proceed as normal.
      params[password_field] = Password.hashed_password(nil, params[password_field])
      super()
    end
  end
end
