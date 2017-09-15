class UserMailer < ActionMailer::Base
  require 'mandrill'
  after_action :send

  def mandrill_client
    @mandrill_client ||= Mandrill::API.new(ENV['MANDRILL_API_KEY'])
  end

  def welcome_email(record, token, _opts)
    confirmation_instructions(record, token)
    @subject = "Welcome to your new fitness portal!"
    counter = fitness_classes_content.count == 2
    @message_vars << {name: "counter", content: counter}
  end

  def reset_password_instructions(record, token, opts={})
    @record = record
    @subject = "We noticed you are resetting your password. Here are some instructions"
    @template_name = "reset-password"

    @message_vars = [
      {name: "USER_NAME", content: user_name },
      {name: "RESET_PASSWORD_URL", content: reset_password_url(token) }
    ]
  end

  def confirmation_instructions(record, token, opts={})
    @record = record
    @subject = "Welcome Email"
    @template_name = "welcome-email"
    @message_vars = [
      {name: "classes", content: fitness_classes_content},
      {name: "dashboard_url", content: root_url(:subdomain => "dashboard")},
      {name: "profile_url", content: user_confirmation_url(confirmation_token: token,:subdomain=>"signup")}
    ]
  end

  private

  def fitness_classes_content
    @record.current_location.group_fitness_info_for_mailchimp
  end

  def reset_password_url(token)
    if @record.class.name == "Admin"
      user_name = @record.username rescue ""
      edit_admin_password_url(reset_password_token: token, subdomain: "admin")
    else
      user_name = @record.profile.first_name rescue ""
      edit_user_password_url(reset_password_token: token, subdomain: "signup")
    end
  end

  def message
    {
     to: [{email: @record.email }],
     from_email: "noreply@contactelevation.com",
     from_name: "Elevation Corporate Health Team",

     subject: @subject,

     merge_vars: [{rcpt: @record.email, vars: [@message_vars]}]
    }
  end

  def send
    mandrill_client.messages.send_template @template_name, [], message
  end
end
