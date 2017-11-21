require 'stax/aws/iam'
require 'stax/aws/sts'

module Stax
  class Iam < Base

    desc 'id', 'get account id'
    def id
      puts Aws::Sts.account_id
    end

    desc 'aliases', 'get account aliases'
    def aliases
      puts Aws::Iam.aliases
    end

  end
end