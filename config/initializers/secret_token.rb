# This is set by instances in Houston::Configuration

if Houston::Application.config.secret_key_base.nil?
  puts "\e[34mDEPRECATION: \e[4mHouston.config.secret_key_base\e[0;34m is not set. Houston is supplying a default value. This fallback functionality will be removed in version 1.0. Set secret_key_base in your `Houston.config` block.\e[0m"

  unless Rails.env.production?
    Houston::Application.config.secret_key_base = "8cf48c792d860953a74ecaa7c779c6019ecddf39a03300a9aed505662f519cf933b4b0ecba3bea4f0eaaf3debd09b08c3e2bd87b9d30be8df0b1166ab4962752"
  else
    Houston::Application.config.secret_key_base = ENV["HOUSTON_SECRET_KEY_BASE"]
  end
end
