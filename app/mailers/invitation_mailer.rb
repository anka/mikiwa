class InvitationMailer < ApplicationMailer
  def invite(user)
    @user = user
    @token = user.generate_token_for(:magic_link)
    @magic_link_url = show_magic_links_url(token: @token)
    mail(to: user.email, subject: "Ihre Einladung zu Mikiwa")
  end
end
