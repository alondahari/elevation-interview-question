class UserMailer < ActionMailer::Base
  require 'mandrill'

  def mandrill_client
    @mandrill_client ||= Mandrill::API.new(ENV['MANDRILL_API_KEY'])
  end

  def welcome_email(record, token, opts={})
    user = record
    template_name = "welcome-email"
    template_content = []
    my_admin = user.current_location
    fitness_classes_content = my_admin.group_fitness_info_for_mailchimp
    counter = (fitness_classes_content.count == 2) ? true : false
    message = {
     to: [{email: user.email }],
     from_email: "noreply@contactelevation.com",
     from_name: "Elevation Corporate Health Team",

     subject: "Welcome to your new fitness portal!",

     merge_vars: [{rcpt: user.email,
      vars: [
             {name: "classes", content: fitness_classes_content},
             {name: "dashboard_url", content: root_url(:subdomain => "dashboard")},
             {name: "profile_url", content: user_confirmation_url(confirmation_token: token,:subdomain=>"signup")},
             {name: "counter", content: counter }
            ]
        }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end

  def reset_password_instructions(record, token, opts={})
    template_name = "reset-password"
    template_content = []
    if record.class.name == "Admin"
      user_name = record.username rescue ""
      reset_password_url = edit_admin_password_url(reset_password_token: token,:subdomain =>"admin")
    else
      user_name = record.profile.first_name rescue ""
      reset_password_url = edit_user_password_url(reset_password_token: token,:subdomain =>"signup")
    end

    message = {
     to: [{email: record.email }],
     from_email: "noreply@contactelevation.com",
     from_name: "Elevation Corporate Health Team",

     subject: "We noticed you are resetting your password. Here are some instructions",
     merge_vars: [{rcpt: record.email,
     vars: [
             {name: "USER_NAME", content: user_name },
             {name: "RESET_PASSWORD_URL", content: reset_password_url }
          ]
        }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end

  def confirmation_instructions(record, token, opts={})
    user = record
    template_name = "welcome-email"
    template_content = []
    my_admin = user.current_location
    fitness_classes_content = my_admin.group_fitness_info_for_mailchimp
    message = {
     to: [{email: user.email }],
     from_email: "noreply@contactelevation.com",
     from_name: "Elevation Corporate Health Team",

     subject: "Welcome Email",

     merge_vars: [{rcpt: user.email,
      vars: [
             {name: "classes", content: fitness_classes_content},
             {name: "dashboard_url", content: root_url(:subdomain => "dashboard")},
             {name: "profile_url", content: user_confirmation_url(confirmation_token: token,:subdomain=>"signup")}
            ]
        }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end

  def contact_email(contact, user_id)
    user = User.find(user_id)
    template_name = "contact-email"
    trainer_message = contact[:message]
    template_content = []
    message = {
     to: [{email: contact[:to_email] }],
     from_email: "noreply@contactelevation.com",
     from_name: user.first_name,
     subject: contact[:subject],
     merge_vars: [{rcpt: contact[:to_email],
     vars: [
             {name: "BODY", content: trainer_message },
             {name: "USER_NAME", content: user.first_name },
             {name: "USER_EMAIL", content: user.email }
          ]
        }
      ]
    }
    mandrill_client.messages.send_template template_name, template_content, message
  end
end
