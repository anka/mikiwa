class MagicLinkMailer < ApplicationMailer
  def login(user)
    @user = user
    @token = user.generate_token_for(:magic_link)
    @magic_link_url = show_magic_links_url(token: @token)
    mail subject: "Mikiwa · Ihr Anmeldelink", to: user.email
  end
end
