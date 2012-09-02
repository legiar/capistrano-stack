require "capistrano"
unless Capistrano::Configuration.respond_to?(:instance)
  abort "Capistrano Stack requires Capistrano 2"
end

begin
  require "capistrano_colors"
rescue LoadError
end

require "capistrano-stack/base"

Capistrano::Configuration.instance(:must_exist).load do
  on :load do
    if exists?(:capistrano_stack)
      capistrano_stack.each do |receipt|
        begin
          require "capistrano-stack/receipts/#{receipt.to_s}"
        rescue LoadError
          abort "Are you misspelled `#{receipt.to_s}` recipe name?"
        end
      end
    end
  end
end  



