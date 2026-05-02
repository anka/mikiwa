class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Mikiwa · Passwort zurücksetzen", to: user.email
  end
end
