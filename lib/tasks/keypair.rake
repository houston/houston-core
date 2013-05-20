require './lib/configuration'

namespace :keypair do
  task :generate do |t|
    if File.exists?(Houston.config.keypair)
      puts "#{Houston.config.keypair} exists"
      exit
    end
    
    tmp = Rails.root.to_s
    
    `openssl genrsa -des3 -passout pass:#{Houston.config.passphrase.shellescape} -out #{tmp}/config/private.pem 2048`
    `openssl rsa -in #{tmp}/config/private.pem -passin pass:#{Houston.config.passphrase.shellescape} -out #{tmp}/config/public.pem -outform PEM -pubout`
    `cat #{tmp}/config/private.pem #{tmp}/config/public.pem >> #{Houston.config.keypair}`
    `rm #{tmp}/config/private.pem #{tmp}/config/public.pem`
  end
end
