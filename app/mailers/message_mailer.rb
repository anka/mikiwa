class MessageMailer < ApplicationMailer
  def notification(message, user)
    @message = message
    @user = user
    @url = inbox_message_url(message)
    mail(to: user.email, subject: "Neue Mitteilung: #{message.title}")
  end
end
