# because user passwords are hashed both on a production server, and locally, a
# random salt can't be added to the password
class ProductionUser < User
  def create_salt_and_hash_password
    self.password_salt = nil
    hash_password
  end

  def hash_password
    return unless password_changed? && password?
    self.password = Password.hashed_password(nil, password)
  end
  
  def passwords_match?(password)
    self.password_was == Password.hashed_password(nil, password) ? self : nil
  end
end
