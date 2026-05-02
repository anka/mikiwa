class MitteilungMailer < ApplicationMailer
  def notification(mitteilung, user)
    @mitteilung = mitteilung
    @user = user
    @url = posteingang_mitteilung_url(mitteilung)
    mail(to: user.email, subject: "Neue Mitteilung: #{mitteilung.title}")
  end
end
