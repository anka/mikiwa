# Preview all emails at http://localhost:3000/rails/mailers/magic_link_mailer
class MagicLinkMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/magic_link_mailer/login
  def login
    MagicLinkMailer.login(User.parents.take)
  end
end
