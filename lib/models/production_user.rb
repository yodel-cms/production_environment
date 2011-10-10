# because user passwords are hashed both on a production server, and locally, a
# random salt can't be added to the password. clients will send the hashed
# version of the password, so a simple comparison to the stored password is ok.
class ProductionUser < User
  def create_salt_and_hash_password
    self.password_salt = nil
  end

  def hash_password
    return unless password_changed? && password?
    self.password = Password.hashed_password(nil, password)
  end
  
  def passwords_match?(password)
    self.password_was == password
  end
end
